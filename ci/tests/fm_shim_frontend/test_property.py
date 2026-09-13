#!/usr/bin/python3 -Bsu

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Hypothesis property tests for fm_shim_frontend.get_path_list_from_uris.
##
## Target rationale: get_path_list_from_uris is the URI-validation
## chokepoint between the FileManager1 D-Bus surface and the user-
## facing dialog. It runs urllib.parse.urlsplit + urllib.parse.unquote
## on attacker-supplied strings, then enforces three independent
## invariants (no Unicode/control chars, no newlines/NUL post-decode,
## absolute-path-only) before the value is shown to the user or
## passed to a file manager. A property-test pass over Hypothesis-
## generated URI lists is the right shape to catch invariant
## violations: the function should never raise on any input (must
## degrade gracefully), and several output properties must hold for
## EVERY entry in the returned list - regardless of input pathology.

# pylint: disable=missing-function-docstring,missing-class-docstring

from pathlib import Path

import pytest
from hypothesis import given, settings, HealthCheck, strategies as st

from fm_shim_frontend.fm_shim_frontend import get_path_list_from_uris


## ----------------------------------------------------------------
## Hypothesis strategies
## ----------------------------------------------------------------

## Arbitrary text that may include Unicode, control chars, NULs,
## newlines, percent escapes, etc. - explicitly UNSANITIZED so we
## probe the function's defensive behavior.
adversarial_text = st.text(
    min_size=0, max_size=200,
    alphabet=st.characters(blacklist_categories=()),
)

## URIs that look plausibly file:// shaped so we exercise the
## post-urlsplit branches (most adversarial_text values fail at the
## scheme/netloc gate). Use 7-bit-ASCII for the URI body and let
## the unquoted path become arbitrary text via percent-escapes.
ascii_safe = st.text(
    min_size=0, max_size=120,
    alphabet=st.characters(min_codepoint=0x20, max_codepoint=0x7E),
)

handler_modes = st.sampled_from([
    "--show-folders",
    "--show-items",
    "--show-item-properties",
])


def _file_uri_from_text(t: str) -> str:
    ## Always produce a file:// URI shape so the input survives the
    ## scheme-check gate at least often enough for the inner code
    ## paths to get exercised.
    import urllib.parse as up
    return "file://" + up.quote(t, safe="/-._~")


file_uri = ascii_safe.map(_file_uri_from_text)

## Mix the two pools: half-and-half adversarial vs file-uri-shaped.
uri_strategy = st.one_of(adversarial_text, file_uri)

uri_list_strategy = st.lists(uri_strategy, min_size=0, max_size=8)


## ----------------------------------------------------------------
## Properties
## ----------------------------------------------------------------

@settings(
    max_examples=300,
    deadline=None,
    suppress_health_check=[HealthCheck.too_slow],
)
@given(handler_mode=handler_modes, uri_list=uri_list_strategy)
def test_never_raises(handler_mode: str, uri_list: list[str]) -> None:
    ## Foundational invariant: no input may crash the function. It
    ## must always return a (possibly empty) list. Hypothesis will
    ## try empty lists, lists of "", lists of malformed URIs,
    ## arbitrary unicode, percent-escaped control chars, etc.
    result = get_path_list_from_uris(handler_mode, uri_list)
    assert isinstance(result, list)
    for p in result:
        assert isinstance(p, Path)


@settings(
    max_examples=300,
    deadline=None,
    suppress_health_check=[HealthCheck.too_slow],
)
@given(handler_mode=handler_modes, uri_list=uri_list_strategy)
def test_output_paths_are_absolute(handler_mode: str, uri_list: list[str]) -> None:
    ## Domain invariant: every Path returned must be absolute. The
    ## function explicitly skips relative paths; this property
    ## guards against future refactors that drop the guard.
    for p in get_path_list_from_uris(handler_mode, uri_list):
        assert p.is_absolute(), f"non-absolute path leaked: {p!r}"


@settings(
    max_examples=300,
    deadline=None,
    suppress_health_check=[HealthCheck.too_slow],
)
@given(handler_mode=handler_modes, uri_list=uri_list_strategy)
def test_output_has_no_dangerous_chars(
    handler_mode: str, uri_list: list[str]
) -> None:
    ## Domain invariant: no path in the output may contain a newline
    ## or a NUL byte. Both are explicitly filtered post-unquote;
    ## this property catches a regression where the filter is moved
    ## or weakened.
    for p in get_path_list_from_uris(handler_mode, uri_list):
        s = str(p)
        assert "\n" not in s, f"newline leaked in output: {s!r}"
        assert "\x00" not in s, f"NUL leaked in output: {s!r}"


@settings(
    max_examples=300,
    deadline=None,
    suppress_health_check=[HealthCheck.too_slow],
)
@given(handler_mode=handler_modes, uri_list=uri_list_strategy)
def test_output_unique_and_sorted(
    handler_mode: str, uri_list: list[str]
) -> None:
    ## Domain invariant: output is deduplicated and sorted (function
    ## docs the dedup via 'set'; the sort is documented at the end).
    ## A regression that drops either property would surprise
    ## downstream callers that rely on stable iteration order.
    out = get_path_list_from_uris(handler_mode, uri_list)
    assert out == sorted(set(out)), \
        f"output not sorted-unique: {out!r}"


@settings(
    max_examples=300,
    deadline=None,
    suppress_health_check=[HealthCheck.too_slow],
)
@given(handler_mode=handler_modes, uri_list=uri_list_strategy)
def test_idempotent_when_paths_are_string_form(
    handler_mode: str, uri_list: list[str]
) -> None:
    ## If we feed the function back its own output (re-encoded as
    ## file:// URIs), the result should be a subset of the original
    ## output (filesystem state may have changed; some entries may
    ## have disappeared, but no NEW entries should appear). This
    ## catches refactors that introduce non-idempotent behavior.
    import urllib.parse as up
    first = get_path_list_from_uris(handler_mode, uri_list)
    re_uris = ["file://" + up.quote(str(p), safe="/-._~") for p in first]
    second = get_path_list_from_uris(handler_mode, re_uris)
    assert set(second).issubset(set(first)), \
        f"second pass introduced paths not in first: " \
        f"first={first!r} second={second!r}"


## ----------------------------------------------------------------
## Targeted regressions
## ----------------------------------------------------------------

@pytest.mark.parametrize("uri", [
    "",                                  # empty
    "file:///\nevil",                    # newline post-decode
    "file:///%00etc/passwd",             # NUL post-decode
    "file:///etc/passwd?query=1",        # query component
    "file:///etc/passwd#frag",           # fragment component
    "http://example.com/etc/passwd",     # non-file scheme
    "file://attacker.example/etc/passwd",  # non-localhost netloc
    "file:relative/path",                # relative
    "file:///" + "A" * 10000,            # very long
    "file:///%C3%A9clair",               # non-ASCII percent-escape
])
def test_known_adversarial_inputs_rejected(uri: str) -> None:
    ## Concrete fixed-input regressions for the categories the
    ## function explicitly defends against. These are NOT
    ## Hypothesis-generated; they nail down specific past or
    ## anticipated bug shapes so a regression is caught immediately
    ## rather than waiting for Hypothesis to rediscover them.
    out = get_path_list_from_uris("--show-folders", [uri])
    assert out == [], f"adversarial URI not rejected: {uri!r} -> {out!r}"

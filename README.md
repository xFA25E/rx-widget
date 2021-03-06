# Table of Contents

1.  [Overview](#org3e8589f)
2.  [Usage](#org424da4a)

Edit regexp widgets as rx forms


<a id="org3e8589f"></a>

# Overview

This package lets you edit regexp widgets as rx forms.  The form is passed
directly to the `rx-to-string` function.  It depends on [xr](https://github.com/mattiase/xr) package to convert
regexps to rx forms.

![img](./rx-widget-scrot.png)


<a id="org424da4a"></a>

# Usage

Just use `rx-widget` in `:type` argument in `defcustom`

    (defcustom my-custom-var
      "\\(?:some\\)?[long]\\(?:regexp\\)+"
      "My var with regexp"
      :type 'rx-widget
      :group 'my-group)

If you want to use it everywhere, you can override default `regexp` widget.

    (define-widget 'regexp 'rx-widget "A regular expression in rx form.")

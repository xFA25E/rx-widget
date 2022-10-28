# Table of Contents

1.  [Overview](#orgef95f07)
2.  [Usage](#org6d4516e)

Edit regexp widgets as rx forms


<a id="orgef95f07"></a>

# Overview

This package lets you edit regexp widgets as rx forms.  The form is passed
directly to the `rx-to-string` function.  It depends on [xr](https://github.com/mattiase/xr) package to convert
regexps to rx forms.

![img](./scrot.png)


<a id="org6d4516e"></a>

# Usage

Just use `rx-widget` in `:type` argument in `defcustom`

    (defcustom my-custom-var
      "\\(?:some\\)?[long]\\(?:regexp\\)+"
      "My var with regexp"
      :type 'rx-widget
      :group 'my-group)

If you want to use it everywhere, you can override default `regexp` widget.

    (with-eval-after-load 'wid-edit
      (require 'rx-widget)
      (define-widget 'regexp 'rx-widget "A regular expression in rx form."))

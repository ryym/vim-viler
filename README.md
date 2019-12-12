# Viler

[![Actions](https://github.com/ryym/vim-viler/workflows/Test/badge.svg)]( https://github.com/ryym/vim-viler/actions)

Viler is a file explorer plugin for Vim, with an ability of editing directory structures by hand.

![](docs/demo.gif)

## Status

v0.0.1 (Beta version)

Currently basic file operations (adding, copying, moving, deleting) should work well.

## Features

- Editable
- Tree view
- Multiple window support

Because you can edit a filer as a normal text, there is no need to configure and remember how to add/copy/move/delete files.
Just edit lines as you like. When you save it Viler detects changes and applies them to the actual file system. 
See [the help document](/doc/viler.txt) for the details.

## Installation

Clone this repository and add this to your `runtimepath`.

If you use [`vim-plug`](https://github.com/junegunn/vim-plug):

```vim
Plug 'ryym/vim-viler'
```

## Limitations

There are some limitations for editing.
We think some of them could be eliminated in future.

- You cannot undo/redo saving.
- You cannot add/edit files inside of an added/edited directory.
- You cannot save multiple filers separately. If you save one filer, all open filers are saved and changes are applied.

" File: autoload/ctrlp/cache.vim
" Author: Takahiro Yoshihara <tacahiroy@gmail.com>
" License: The MIT License
" Copyright (c) 2014 Takahiro Yoshihara

" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:

" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.

" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

if get(g:, 'loaded_ctrlp_funky_cache', 0)
  finish
endif
let g:loaded_ctrlp_funky_cache = 1

let s:saved_cpo = &cpo
set cpo&vim

let s:fu = ctrlp#funky#utils#new()

let s:cache = {}
let s:cache.list = {}
let s:cache.dir = ''

" private: {{{
function! s:ftime(bufnr)
  return getftime(s:fu.fname(a:bufnr))
endfunction

function! s:fsize(bufnr)
  return getfsize(s:fu.fname(a:bufnr))
endfunction

function! s:timesize(bufnr)
  return string(s:ftime(a:bufnr)) . string(s:fsize(a:bufnr))
endfunction
" }}}

function! ctrlp#funky#cache#new(dir)
  if empty(a:dir)
    echoerr 'cache dir must be specified!!'
    return ''
  endif
  let s:cache.dir = a:dir
  return s:cache
endfunction

function! s:cache.save(bufnr, defs)
  let h = s:timesize(a:bufnr)
  let fname = s:fu.fname(a:bufnr)
  " save function defs
  let self.list[fname] = extend([h], a:defs)
  call writefile(self.list[fname], s:fu.path(self.dir, fname))
endfunction

function! s:cache.load(bufnr)
  call self.read(a:bufnr)
  " first line is hash value
  return self.list[s:fu.fname(a:bufnr)][1:-1]
endfunction

function! s:cache.read(bufnr)
  let fname = s:fu.fname(a:bufnr)
  let cache_file = s:fu.path(self.dir, fname)
  if empty(get(self.list, fname, {}))
    let self.list[fname] = []
    if filereadable(cache_file)
      let self.list[fname] = readfile(cache_file)
    endif
  endif
endfunction

function! s:cache.clear(path)
  " files needn't to be readable for deletion
  if !empty(glob(path))
    if !delete(path)
      echoerr 'ERR: cannot delete a cache file - ' . path
  endif
  return ''
endfunction

function! s:cache.delete(...)
  let bufnr = get(a:, 1, -1)
  let path = s:fu.path(self.dir, s:fu.fname(bufnr))
endfunction

function! s:cache.timesize(bufnr)
  call self.read(a:bufnr)
  let fname = s:fu.fname(a:bufnr)
  return get(get(self.list, fname, []), 0, '')
endfunction

function! s:cache.is_maybe_unchanged(bufnr)
  if !s:fu.is_real_file(a:bufnr) | return 0 | endif
  let prev = self.timesize(a:bufnr)
  let cur = s:timesize(a:bufnr)
  call s:fu.debug(prev . ' = ' . cur . ': ' . (prev == cur ? 'unchanged' : 'changed'))
  return prev == cur
endfunction

let &cpo = s:saved_cpo
unlet s:saved_cpo

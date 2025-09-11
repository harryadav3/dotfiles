# -*- coding: utf-8 -*-
# This file contains ranger's commands.
# It's all in python; lines beginning with # are comments.

from ranger.api.commands import *
from ranger.core.loader import CommandLoader
import subprocess
import os

# Custom commands

class quickLook(Command):
    """:quicklook
    Preview the selected file with a preview tool
    """

    context = 'browser'

    def execute(self):
        self.fm.execute_file(
                files = [f for f in self.fm.thistab.get_selection()],
                app = 'xdg-open',
                flags = 'f')

class trash(Command):
    """:trash [-q]
    Moves the selected files to trash
    Optionally takes the -q flag to suppress listing the files
    afterwards.
    """

    def execute(self):
        # Determine the best trash command available
        if os.path.exists('/usr/bin/trash-put'):
            # If trash-cli is installed
            action = ['trash-put']
        elif os.path.exists('/usr/bin/gio'):
            # Use gio for trashing
            action = ['gio', 'trash']
        elif os.path.exists('/usr/bin/trash'):
            # Standard trash command
            action = ['trash']
        else:
            # Fallback to manual trashing
            trash_dir = os.path.expanduser("~/.local/share/Trash/files")
            if not os.path.exists(trash_dir):
                os.makedirs(trash_dir)
            action = ['mv', '-f', '--backup=numbered']
            
        action.extend(f.path for f in self.fm.thistab.get_selection())
        
        if action[0] == 'mv':
            action.append(trash_dir)
            
        self.fm.execute_command(action)

        # Echoes the basenames of the trashed files
        if not self.rest(1) == "-q":
            names = []
            names.extend(f.basename for f in self.fm.thistab.get_selection())
            self.fm.notify("Files moved to the trash: " + ', '.join(map(str, names)))

class fzf_select(Command):
    """
    :fzf_select
    Find a file using fzf.
    With a prefix argument select only directories.
    See: https://github.com/junegunn/fzf
    """
    def execute(self):
        import subprocess
        import os.path
        
        if self.quantifier:
            # match only directories
            command="find -L . \( -path '*/\.*' -o -fstype 'dev' -o -fstype 'proc' \) -prune \
            -o -type d -print 2> /dev/null | sed 1d | cut -b3- | fzf +m"
        else:
            # match files and directories
            command="find -L . \( -path '*/\.*' -o -fstype 'dev' -o -fstype 'proc' \) -prune \
            -o -print 2> /dev/null | sed 1d | cut -b3- | fzf +m"
        
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)

class compress(Command):
    """:compress

    Compress marked files to current directory
    """
    def execute(self):
        cwd = self.fm.thisdir
        marked_files = cwd.get_selection()

        if not marked_files:
            return

        def refresh(_):
            cwd = self.fm.thisdir
            cwd.load_content()

        descr = "compressing files in: " + os.path.basename(self.fm.thisdir.path)
        obj = CommandLoader(args=['apack'] + [os.path.basename(f.path) for f in marked_files], descr=descr, read=True)

        obj.signal_bind('after', refresh)
        self.fm.loader.add(obj)

    def tab(self, tabnum):
        """ Complete with current folder name """

        extension = ['.zip', '.tar.gz', '.rar', '.7z']
        return ['compress ' + os.path.basename(self.fm.thisdir.path) + ext for ext in extension]

class extract(Command):
    """:extract

    Extract selected archives
    """
    def execute(self):
        cwd = self.fm.thisdir
        marked_files = cwd.get_selection()

        def refresh(_):
            cwd = self.fm.thisdir
            cwd.load_content()

        def atool_extract(file):
            return ['aunpack', file.path]

        for file in marked_files:
            descr = "extracting: " + file.path
            obj = CommandLoader(args=atool_extract(file), descr=descr, read=True)
            obj.signal_bind('after', refresh)
            self.fm.loader.add(obj)

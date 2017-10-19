import vim
import sys

def dbg(ln, sid, txt):
    sys.stdout.write("line %d, sid %s : %s\n" % (ln, sid, txt))

def indent_guess_real(char, ind):
    hg_names = ['Comment', 'Constant']
    hg_ids = []
    for n in hg_names:
        hg_ids.append(vim.eval('synIDtrans(hlID("%s"))' % n))

    space_found = False
    buf = vim.current.buffer
    blen = len(buf)
    inds = set()

    def get_line_indent(sid, line):
        if sid in hg_ids:
            return 'skip', 'groups'
        if not line or line.isspace():
            return 'skip', 'empty'
        if not line[0].isspace():
            return 'skip', 'no indent'
        if line[0] == '\t' and not space_found:
            return 'tab', 'first tab'
        if line[0] != ' ':
            return 'skip', 'not a space'
        return 'space', 2

    for i in range(1, min(blen, 120)):
        line = buf[i - 1]
        sid = vim.eval("synIDtrans(synID(%d, 1, 1))" % i)
        info = get_line_indent(sid, line)
        # dbg(i, sid, str(info))
        if info[0] == 'skip':
            continue
        if info[0] == 'tab':
            return 'tab', ind

        space_found = True
        ind_len = 0
        for j in line:
            if j != ' ':
                break
            ind_len += 1
        if ind_len > 1:
            inds.add(ind_len)

    if inds:
        ind = min(inds)
        char = 'space'

    return char, ind


def indent_guess():
    char, ind = indent_guess_real('space', 4)
    vim.eval("IndentSet('%s',%d)" % (char, ind))


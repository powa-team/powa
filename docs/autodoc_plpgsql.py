from sphinx.ext.autodoc import Documenter
from sphinx.util.console import bold
from sphinxcontrib.domaintools import custom_domain, GenericObject
from sphinx.util.docfields import Field, GroupedField, TypedField
from sphinx.locale import _ as l_, _
from sphinx import addnodes
from sphinx.util import ws_re

import requests


class PLPGSQLDocumenter(Documenter):
    """
    Specialized documenter for plpgsqlcode
    """
    objtype = 'plpgsql'

    option_spec = {
        'src': lambda x: x
    }

    @classmethod
    def can_document_member(cls, *args, **kwargs):
        return False  # stop documenters chain


    def parse(self, content):
        in_comment_block = False
        comment_block_indent_len = 0
        comment_starts_with = '/*"""'
        comment_ends_with = '*/'
        # Code lifted from sphinxcontrib-autoanysrc
        for lineno, srcline in enumerate(content.split('\n')):
            # remove indent
            line = srcline.lstrip()
            # check block begins
            if not in_comment_block \
                    and line.startswith(comment_starts_with):
                in_comment_block = True
                comment_block_indent_len = len(srcline) - len(line)
                continue  # goto next line

            # skip if line is not a docs
            if not in_comment_block:
                continue

            # check blocks ends
            if line.startswith(comment_ends_with):
                in_comment_block = False
                yield '', lineno  # empty line in docs
                continue  # goto next line

            # calculate indent
            indent_len = len(srcline) - len(line) - comment_block_indent_len
            if srcline and indent_len:
                indent_char = srcline[0]
                line = indent_char * indent_len + line

            yield line, lineno


    def generate(self, more_content=None, real_modname=None,
            check_module=False, all_members=False):
        import conf
        # start generate docs
        self.add_line('', '<autoplpgsql>')

        # set default domain if it specified in anaylyzer instance
        self.add_line(
            '.. default-domain:: psql', '<autoplpgsql>'
        )
        self.add_line('', '<autoplpgsql>')
        url = self.options.src.format(**conf.__dict__)
        data = requests.get(url)
        self.directive.env.note_dependency(url)
        content = data.text
        for line, lineno in self.parse(content):
            self.add_line(line, url, lineno)


class SqlObject(GenericObject):

    def handle_signature(self, sig, signode):
        if self.parse_node:
            name = self.parse_node(self.env, sig, signode)
        else:
            signode.clear()
            signode.insert(0, addnodes.desc_annotation(self.objtype, self.objtype))
            signode += addnodes.desc_name(sig, sig)
            # normalize whitespace like XRefRole does
            name = ws_re.sub('', sig)
        return name



def setup(app):
    app.add_autodocumenter(PLPGSQLDocumenter)
    my_domain = custom_domain('PSQLDomain',
            name  = 'psql',
            label = "PostgreSQL",

            elements = dict(
                function = dict(
                    objname      = "Function",
                    role = "func",
                    domain_object_class = SqlObject,
                    indextemplate = "pair: %s; pl/pgsql function",
                ),
                view = dict(
                    objname = "View",
                    domain_object_class = SqlObject,
                    indextemplate = "pair: %s; SQL View"
                ),
                type = dict(
                    objname = 'Type',
                    domain_object_class = SqlObject,
                    indextemplate = "pair: %s; SQL Type"),
    ))
    # Monkey patch for python3 support
    def get_objects(self):
        for (type, name), info in self.data['objects'].items():
            yield (name, name, type, info[0], info[1],
                   self.object_types[type].attrs['searchprio'])

    def clear_doc(self, docname):
      if 'objects' in self.data:
        for key, (fn, _) in list(self.data['objects'].items()):
            if fn == docname:
                del self.data['objects'][key]


    my_domain.get_objects = get_objects
    my_domain.clear_doc = clear_doc
    app.add_domain(my_domain)
    return {
        'version': '0.0.0',  # where docs?
        'parallel_read_safe': True,
    }

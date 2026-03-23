import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Change default sort mode to 'name'
code = code.replace("String _sortMode = 'status'; // default sort by status", "String _sortMode = 'name'; // default sort by name")

# 2. Fix the name sorting logic which crashes on Portainer's List type `Names`
sort_old = """      displayList.sort((a, b) {
        if (_sortMode == 'name') {
           String nameA = a['name'] ?? a['Names'] ?? '';
           String nameB = b['name'] ?? b['Names'] ?? '';
           return nameA.toLowerCase().compareTo(nameB.toLowerCase());"""

sort_new = """      displayList.sort((a, b) {
        if (_sortMode == 'name') {
           String getName(dynamic c) {
             if (c['Names'] != null && c['Names'] is List && c['Names'].isNotEmpty) {
               return c['Names'][0].toString().replaceAll('/', '');
             }
             if (c['name'] != null) return c['name'].toString();
             if (c['Names'] != null) return c['Names'].toString();
             return '';
           }
           return getName(a).toLowerCase().compareTo(getName(b).toLowerCase());"""

code = code.replace(sort_old, sort_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

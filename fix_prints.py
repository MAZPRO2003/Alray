import os

def fix_print(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if "import 'package:flutter/foundation.dart';" not in content:
        content = "import 'package:flutter/foundation.dart';\n" + content
        
    content = content.replace('print(', 'debugPrint(')
    
    with open(filepath, 'w') as f:
        f.write(content)

fix_print('lib/providers/contacts_provider.dart')
fix_print('lib/services/weather_service.dart')

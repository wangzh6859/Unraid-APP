import re

with open('lib/api/emby_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Instead of just IncludeItemTypes: 'Movie,Series', Emby has 'Anime', 'Episode', 'Folder' or we just remove IncludeItemTypes to get ALL media types!
# Let's remove IncludeItemTypes entirely, or explicitly add 'Movie,Series,Anime,Episode'
new_query = """        queryParameters: {
          'Limit': 20, // 获取更多以展示
          'Fields': 'PrimaryImageAspectRatio',
          'IncludeItemTypes': 'Movie,Series,Episode,Anime'
        },"""
code = re.sub(r"queryParameters: \{.*?'Fields': 'PrimaryImageAspectRatio'\s*\},", new_query.strip(), code, flags=re.DOTALL)
# Actually, if we just remove IncludeItemTypes, it fetches everything Latest.
new_query2 = """        queryParameters: {
          'Limit': 20,
          'Fields': 'PrimaryImageAspectRatio',
          'IsFolder': false
        },"""
code = re.sub(r"queryParameters: \{.*?'IncludeItemTypes': 'Movie,Series,Episode,Anime'\s*\},", new_query2.strip(), code, flags=re.DOTALL)
# Wait, just in case my regex missed:
code = code.replace("'IncludeItemTypes': 'Movie,Series'", "'IsFolder': false")

with open('lib/api/emby_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)


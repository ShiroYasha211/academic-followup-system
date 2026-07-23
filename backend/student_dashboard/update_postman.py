import json
import os

collection_path = r'e:\Projects\student_dashboard\Attendify_Student_API.postman_collection.json'

with open(collection_path, 'r', encoding='utf-8') as f:
    collection = json.load(f)

# 1. Update Login description and body and headers
for item in collection['item']:
    if item['name'] == '🔐 Authentication':
        for sub_item in item['item']:
            if sub_item['name'] == 'Login':
                sub_item['request']['body']['raw'] = '{\n    "login": "student1@example.com",\n    "password": "password"\n}'
                sub_item['request']['description'] = "تسجيل الدخول كطالب للحصول على Bearer Token.\nيُحفظ الـ Token تلقائياً في المجموعة.\n\nيمكنك استخدام البريد الإلكتروني أو الرقم الأكاديمي في حقل login.\n\nالحقول المطلوبة:\n- login (string, required): email or student_number\n- password (string, required)"

# 2. Add New Folders and Items
def find_folder(name):
    for item in collection['item']:
        if item.get('name') == name:
            return item
    return None

def add_item_to_folder(folder_name, new_item):
    folder = find_folder(folder_name)
    if folder:
        folder['item'].append(new_item)
    else:
        # Create folder if not exists
        collection['item'].append({
            "name": folder_name,
            "item": [new_item]
        })

# --- Attendance & Grades ---
grades_item = {
    "name": "My Grades (JSON)",
    "request": {
        "method": "GET",
        "header": [{"key": "Accept", "value": "application/json"}],
        "url": {"raw": "{{base_url}}/grades", "host": ["{{base_url}}"], "path": ["grades"]},
        "description": "الحصول على درجات الطالب موزعة حسب المواد والفئات."
    }
}
add_item_to_folder("📊 Attendance & Grades", grades_item)

# --- Authorized Grades ---
auth_grades_folder = {
    "name": "👮 Authorized Grades",
    "description": "ادخال الدرجات للزملاء (للمناديب المخولين فقط)",
    "item": [
        {
            "name": "List My Delegations",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/authorized-grades", "host": ["{{base_url}}"], "path": ["authorized-grades"]},
                "description": "عرض الفئات التي تم تفويضك لإدخال درجاتها."
            }
        },
        {
            "name": "Get Category Students",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/authorized-grades/1", "host": ["{{base_url}}"], "path": ["authorized-grades", "1"]},
                "description": "عرض قائمة الطلاب والدرجات المسجلة في فئة معينة."
            }
        },
        {
            "name": "Store Grades",
            "request": {
                "method": "POST",
                "header": [{"key": "Accept", "value": "application/json"}, {"key": "Content-Type", "value": "application/json"}],
                "body": {
                    "mode": "raw",
                    "raw": "{\n    \"grades\": [\n        {\"student_id\": 1, \"score\": 15},\n        {\"student_id\": 2, \"score\": 14}\n    ]\n}"
                },
                "url": {"raw": "{{base_url}}/authorized-grades/1", "host": ["{{base_url}}"], "path": ["authorized-grades", "1"]},
                "description": "حفظ الدرجات للفئة المفوضة."
            }
        }
    ]
}
collection['item'].append(auth_grades_folder)

# --- Subscription ---
sub_folder = {
    "name": "💳 Subscription",
    "item": [
        {
            "name": "Subscription Status",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/subscription", "host": ["{{base_url}}"], "path": ["subscription"]}
            }
        },
        {
            "name": "Redeem Voucher",
            "request": {
                "method": "POST",
                "header": [{"key": "Accept", "value": "application/json"}, {"key": "Content-Type", "value": "application/json"}],
                "body": {"mode": "raw", "raw": "{\"code\": \"ABCD1234EFGH\"}"},
                "url": {"raw": "{{base_url}}/subscription/redeem", "host": ["{{base_url}}"], "path": ["subscription", "redeem"]}
            }
        },
        {
            "name": "Subscribe to Package",
            "request": {
                "method": "POST",
                "header": [{"key": "Accept", "value": "application/json"}, {"key": "Content-Type", "value": "application/json"}],
                "body": {"mode": "raw", "raw": "{\"package_id\": 1}"},
                "url": {"raw": "{{base_url}}/subscription/subscribe", "host": ["{{base_url}}"], "path": ["subscription", "subscribe"]}
            }
        }
    ]
}
collection['item'].append(sub_folder)

# --- PDF Reports ---
reports_folder = {
    "name": "📄 PDF Reports",
    "item": [
        {
            "name": "Attendance PDF Link",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/reports/attendance", "host": ["{{base_url}}"], "path": ["reports", "attendance"]}
            }
        },
        {
            "name": "Grades PDF Link",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/reports/grades", "host": ["{{base_url}}"], "path": ["reports", "grades"]}
            }
        }
    ]
}
collection['item'].append(reports_folder)

# Save the updated collection
with open(collection_path, 'w', encoding='utf-8') as f:
    json.dump(collection, f, ensure_ascii=False, indent=4)

print("Postman collection updated successfully.")

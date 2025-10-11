import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

cred = credentials.Certificate("Stampd/GoogleService-Info.plist")
firebase_admin.initialize_app(cred)

db = firestore.client()

def claim_code(code):
    doc_ref = db.collection("codes").document(code)
    doc = doc_ref.get()
    if doc.exists:
        return doc.to_dict()
    return None
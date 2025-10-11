import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import qrcode
import json
import uuid
import os
from PIL import Image
import base64

# Initialize Firebase
def initialize_firebase():
    try:
        # Try to get existing app
        firebase_admin.get_app()
        print("✅ Firebase app already initialized")
        return firestore.client()
    except ValueError:
        # Initialize new app
        try:
            # Use service account key
            if os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
                firebase_admin.initialize_app()
                return firestore.client()
            
            # Try to use the service account key file
            service_account_path = "/Users/wenggeiwong/Stampd/Stampd/stampd-a90ad-firebase-adminsdk-fbsvc-3b5e407a56.json"
            if os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                return firestore.client()
            else:
                print("❌ Firebase service account key not found")
                return None
        except Exception as e:
            print(f"❌ Error initializing Firebase: {e}")
            return None

db = initialize_firebase()

class StampQRCode:
    def __init__(self, db_client=None):
        self.db = db_client or db
        self.qr_codes_dir = "/Users/wenggeiwong/Stampd/Stampd/qr_codes"
        self.ensure_qr_directory()
    
    def business_scan_customer_qr(self, qr_data_string, business_id, business_name):
        """
        Business-side method to scan customer QR codes and add stamps
        
        Args:
            qr_data_string: JSON string from scanned customer QR code
            business_id: ID of the business scanning (from business login)
            business_name: Name of the business scanning

        
        Returns:
            dict: Result of the stamp addition with business context
        """
        try:
            # Parse QR code data
            qr_data = json.loads(qr_data_string)
            
            # Validate QR code
            if not self.validate_qr_code(qr_data):
                return {"success": False, "error": "Invalid or expired QR code"}
            
            username = qr_data["username"]
            user_email = qr_data["email"]
            
            # Verify business exists in database
            business_doc = self.db.collection("businesses").document(business_id).get()
            if not business_doc.exists:
                return {"success": False, "error": f"Business {business_name} not found in database"}
            
            business_data = business_doc.to_dict()
            
            # Check if business is active
            if not business_data.get("isActive", False):
                return {"success": False, "error": f"Business {business_name} is not active"}
            
            # Check if customer document exists for this business
            customer_doc_id = f"{username}_{business_id}"
            customer_doc_ref = self.db.collection("customers").document(customer_doc_id)
            customer_doc = customer_doc_ref.get()
            
            if customer_doc.exists:
                # Update existing customer document
                customer_data = customer_doc.to_dict()
                current_stamps = customer_data.get("currentStamps", 0)
                stamps_needed = customer_data.get("stampsNeeded", business_data.get("stampsNeeded", 10))
                
                # Add one stamp
                new_stamp_count = current_stamps + 1
                
                # Check if customer has enough stamps for reward
                reward_claimed = False
                if new_stamp_count >= stamps_needed:
                    reward_claimed = True
                
                # Update the document
                update_data = {
                    "currentStamps": new_stamp_count,
                    "claimed": reward_claimed,
                    "businessVerified": True
                }
                
                customer_doc_ref.update(update_data)
                
                # Update business statistics
                self.update_business_stats(business_id, 1, reward_claimed)
                
                print(f"✅ Business {business_name} added stamp for {username}")
                print(f"📊 Stamps: {new_stamp_count}/{stamps_needed}")
                
                result = {
                    "success": True,
                    "business_name": business_name,
                    "current_stamps": new_stamp_count,
                    "stamps_needed": stamps_needed,
                    "reward_earned": reward_claimed,
                    "message": f"Stamp added! {new_stamp_count}/{stamps_needed} stamps"
                }
                
                if reward_claimed:
                    result["reward_message"] = f"🎉 {username} has earned a reward at {business_name}!"
                    print(f"🎉 {username} has earned a reward at {business_name}!")
                
                return result
                
            else:
                # Create new customer document for this business
                new_customer_data = {
                    "username": username,
                    "email": user_email,
                    "accountType": "Customer",
                    "businessName": business_name,
                    "businessId": business_id,
                    "currentStamps": 1,
                    "stampsNeeded": business_data.get("stampsNeeded", 10),
                    "prizeOffered": business_data.get("prizeOffered", f"Free item at {business_name}"),
                    "logoUrl": business_data.get("logoUrl", f"https://example.com/logos/{business_id}.png"),
                    "claimed": False,
                }
                
                customer_doc_ref.set(new_customer_data)
                
                # Update business statistics
                self.update_business_stats(business_id, 1, False)
                
                print(f"✅ Business {business_name} created new stamp card for {username}")
                print(f"📊 Stamps: 1/{business_data.get('stampsNeeded', 10)}")
                
                return {
                    "success": True,
                    "customer_username": username,
                    "business_name": business_name,
                    "current_stamps": 1,
                    "stamps_needed": business_data.get("stampsNeeded", 10),
                    "reward_earned": False,
                    "new_customer": True,
                    "message": f"New stamp card created! 1/{business_data.get('stampsNeeded', 10)} stamps"
                }
                
        except json.JSONDecodeError:
            return {"success": False, "error": "Invalid QR code format"}
        except Exception as e:
            print(f"❌ Error processing business scan: {e}")
            return {"success": False, "error": str(e)}
    
    def update_business_stats(self, business_id, stamps_given, reward_earned):
        """Update business statistics after scanning"""
        try:
            business_ref = self.db.collection("businesses").document(business_id)
            
            # Get current stats
            business_doc = business_ref.get()
            if business_doc.exists:
                business_data = business_doc.to_dict()
                current_stamps = business_data.get("totalStampsGiven", 0)
                current_rewards = business_data.get("rewardsRedeemed", 0)
                
                # Update stats
                update_data = {
                    "totalStampsGiven": current_stamps + stamps_given
                }
                
                if reward_earned:
                    update_data["rewardsRedeemed"] = current_rewards + 1
                
                business_ref.update(update_data)
                
        except Exception as e:
            print(f"⚠️ Warning: Could not update business stats: {e}")
    
    def get_business_scan_history(self, business_id, limit=50):
        """Get recent scan history for a business"""
        try:
            # Query recent customer interactions for this business
            customers_ref = self.db.collection("customers")
            query = customers_ref.where("businessId", "==", business_id).order_by("lastVisit", direction=firestore.Query.DESCENDING).limit(limit)
            
            docs = query.stream()
            scan_history = []
            
            for doc in docs:
                data = doc.to_dict()
                scan_history.append({
                    "customer_username": data.get("username", "Unknown"),
                    "current_stamps": data.get("currentStamps", 0),
                    "stamps_needed": data.get("stampsNeeded", 10),
                    "reward_earned": data.get("claimed", False),
                    "last_visit": data.get("lastVisit", None)
                })
            
            return {"success": True, "scan_history": scan_history}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_business_dashboard(self, business_id):
        """Get business dashboard data"""
        try:
            # Get business info
            business_doc = self.db.collection("businesses").document(business_id).get()
            if not business_doc.exists:
                return {"success": False, "error": "Business not found"}
            
            business_data = business_doc.to_dict()
            
            # Get customer count for this business
            customers_ref = self.db.collection("customers")
            query = customers_ref.where("businessId", "==", business_id)
            customer_count = len(list(query.stream()))
            
            # Get recent activity
            recent_activity = self.get_business_scan_history(business_id, 10)
            
            return {
                "success": True,
                "business_info": {
                    "business_name": business_data.get("businessName", "Unknown"),
                    "category": business_data.get("category", "Unknown"),
                    "location": business_data.get("location", "Unknown"),
                    "prize_offered": business_data.get("prizeOffered", "Unknown"),
                    "stamps_needed": business_data.get("stampsNeeded", 10),
                    "minimum_purchase": business_data.get("minimumPurchase", 0),
                    "total_customers": customer_count,
                    "total_stamps_given": business_data.get("totalStampsGiven", 0),
                    "rewards_redeemed": business_data.get("rewardsRedeemed", 0)
                },
                "recent_activity": recent_activity.get("scan_history", []) if recent_activity.get("success") else []
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def ensure_qr_directory(self):
        """Create QR codes directory if it doesn't exist"""
        if not os.path.exists(self.qr_codes_dir):
            os.makedirs(self.qr_codes_dir)
            print(f"📁 Created QR codes directory: {self.qr_codes_dir}")
    
    def generate_user_qr_code(self, username, user_email):
        """
        Generate a single universal QR code for a user that works at all businesses
        
        Args:
            username: User's username
            user_email: User's email
        
        Returns:
            dict: QR code information including file path and data
        """
        try:
            # Generate unique universal QR code data (no business_id)
            qr_data = {
                "type": "universal_stamp_card",
                "username": username,
                "email": user_email,
                "qr_id": str(uuid.uuid4())
            }
            
            # Convert to JSON string for QR code
            qr_json = json.dumps(qr_data)
            
            # Generate QR code
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(qr_json)
            qr.make(fit=True)
            
            # Create QR code image
            qr_image = qr.make_image(fill_color="black", back_color="white")
            
            # Generate filename (universal QR code)
            filename = f"{username}_universal_qr.png"
            filepath = os.path.join(self.qr_codes_dir, filename)
            
            # Save QR code image
            qr_image.save(filepath)
            
            # Store QR code metadata in Firestore
            qr_doc_data = {
                "username": username,
                "email": user_email,
                "qr_id": qr_data["qr_id"],
                "qr_data": qr_json,
                "file_path": filepath,
                "type": "universal"
            }
            
            # Save to Firestore
            doc_ref = self.db.collection("qr_codes").document(qr_data["qr_id"])
            doc_ref.set(qr_doc_data)
            
            print(f"✅ Generated universal QR code for {username}")
            print(f"📄 File saved: {filepath}")
            print(f"🔗 QR ID: {qr_data['qr_id']}")
            print(f"🌐 This QR code works at ALL businesses!")
            
            return {
                "success": True,
                "qr_id": qr_data["qr_id"],
                "file_path": filepath,
                "qr_data": qr_data,
                "type": "universal"
            }
            
        except Exception as e:
            print(f"❌ Error generating QR code: {e}")
            return {"success": False, "error": str(e)}
    
    def scan_qr_code(self, qr_data_string, business_id, business_name):
        """
        Process a scanned QR code to add a stamp to user's card
        
        Args:
            qr_data_string: JSON string from scanned QR code
            business_id: ID of the business scanning the QR code
            business_name: Name of the business scanning the QR code
        
        Returns:
            dict: Result of the stamp addition
        """
        try:
            # Parse QR code data
            qr_data = json.loads(qr_data_string)
            
            # Validate QR code
            if not self.validate_qr_code(qr_data):
                return {"success": False, "error": "Invalid or expired QR code"}
            
            username = qr_data["username"]
            user_email = qr_data["email"]
            
            # Check if user exists in Firestore
            customer_doc_id = f"{username}_{business_id}"
            doc_ref = self.db.collection("customers").document(customer_doc_id)
            
            # Try to get existing customer document
            doc = doc_ref.get()
            
            if doc.exists:
                # Update existing customer document
                customer_data = doc.to_dict()
                current_stamps = customer_data.get("currentStamps", 0)
                stamps_needed = customer_data.get("stampsNeeded", 10)
                
                # Add one stamp
                new_stamp_count = current_stamps + 1
                
                # Check if customer has enough stamps for reward
                reward_claimed = False
                if new_stamp_count >= stamps_needed:
                    reward_claimed = True
                
                # Update the document
                doc_ref.update({
                    "currentStamps": new_stamp_count,
                    "claimed": reward_claimed
                })
                
                print(f"✅ Added stamp for {username} at {business_name}")
                print(f"📊 Stamps: {new_stamp_count}/{stamps_needed}")
                
                if reward_claimed:
                    print(f"🎉 {username} has earned a reward at {business_name}!")
                
                return {
                    "success": True,
                    "username": username,
                    "business_name": business_name,
                    "current_stamps": new_stamp_count,
                    "stamps_needed": stamps_needed,
                    "reward_earned": reward_claimed,
                    "message": f"Stamp added! {new_stamp_count}/{stamps_needed} stamps"
                }
                
            else:
                # Create new customer document for this business
                new_customer_data = {
                    "username": username,
                    "email": user_email,
                    "phoneNumber": None,  # Will be updated when user provides it
                    "accountType": "Customer",
                    "businessName": business_name,
                    "businessId": business_id,
                    "currentStamps": 1,
                    "stampsNeeded": 10,  # Default to 10 stamps
                    "prizeOffered": f"Free item at {business_name}",
                    "logoUrl": f"https://example.com/logos/{business_id}.png",
                    "claimed": False
                }
                
                doc_ref.set(new_customer_data)
                
                print(f"✅ Created new stamp card for {username} at {business_name}")
                print(f"📊 Stamps: 1/10")
                
                return {
                    "success": True,
                    "username": username,
                    "business_name": business_name,
                    "current_stamps": 1,
                    "stamps_needed": 10,
                    "reward_earned": False,
                    "message": "New stamp card created! 1/10 stamps",
                    "new_customer": True
                }
                
        except json.JSONDecodeError:
            return {"success": False, "error": "Invalid QR code format"}
        except Exception as e:
            print(f"❌ Error processing QR code: {e}")
            return {"success": False, "error": str(e)}
    
    def validate_qr_code(self, qr_data):
        """Validate QR code data"""
        try:
            # Check if QR code has required fields
            required_fields = ["type", "username", "email", "qr_id"]
            for field in required_fields:
                if field not in qr_data:
                    return False
            
            # Check if QR code type is correct (accept both old and new types)
            if qr_data["type"] not in ["stamp_card", "universal_stamp_card"]:
                return False
            
            # Check if QR code is still active in Firestore
            qr_doc = self.db.collection("qr_codes").document(qr_data["qr_id"]).get()
            if not qr_doc.exists:
                return False
            
            qr_doc_data = qr_doc.to_dict()
            if not qr_doc_data.get("is_active", False):
                return False
            
            return True
            
        except Exception:
            return False
    
    def get_user_stamp_cards(self, username):
        """Get all stamp cards for a user"""
        try:
            # Query all customer documents for this user
            customers_ref = self.db.collection("customers")
            query = customers_ref.where("username", "==", username)
            docs = query.stream()
            
            stamp_cards = []
            for doc in docs:
                data = doc.to_dict()
                stamp_cards.append({
                    "business_name": data.get("businessName", "Unknown"),
                    "business_id": data.get("businessId", "Unknown"),
                    "current_stamps": data.get("currentStamps", 0),
                    "stamps_needed": data.get("stampsNeeded", 10),
                    "prize_offered": data.get("prizeOffered", "Unknown"),
                    "claimed": data.get("claimed", False),
                    "last_visit": data.get("lastVisit", None)
                })
            
            return {"success": True, "stamp_cards": stamp_cards}
            
        except Exception as e:
            return {"success": False, "error": str(e)}

def main():
    """Main function to demonstrate universal QR code functionality with business scanning"""
    if not db:
        print("❌ Firebase not initialized. Please check your credentials.")
        return
    
    qr_system = StampQRCode(db)
    
    print("🎯 Universal Stamp QR Code System with Business Scanning")
    print("=" * 60)
    
    # Example: Generate ONE universal QR code for a user
    print("\n1. Generating universal QR code for user 'john_doe_123'...")
    
    # Generate single universal QR code (works at ANY business)
    universal_qr = qr_system.generate_user_qr_code(
        username="john_doe_123",
        user_email="john.doe@example.com"
    )
    
    if not universal_qr["success"]:
        print(f"❌ Failed to generate QR code: {universal_qr['error']}")
        return
    
    print("\n2. Business Scanning Simulation...")
    
    # Simulate businesses scanning the SAME QR code
    businesses = [
        ("coffee_corner_001", "Coffee Corner", "Sarah"),
        ("pizza_palace_002", "Pizza Palace", "Mike"),
        ("smoothie_station_003", "Smoothie Station", "Emma")
    ]
    
    qr_data_json = json.dumps(universal_qr["qr_data"])
    
    for business_id, business_name in businesses:
        print(f"\n🏪 {business_name} scanning customer QR code...")
        
        # Use the new business scanning method
        result = qr_system.business_scan_customer_qr(
            qr_data_string=qr_data_json,
            business_id=business_id,
            business_name=business_name
        )
        
        if result["success"]:
            print(f"✅ {result['message']}")
            if result.get("reward_earned"):
                print(f"🎉 {result['reward_message']}")
            if result.get("new_customer"):
                print(f"🆕 New customer card created at {business_name}")
        else:
            print(f"❌ Error: {result['error']}")
    
    print("\n3. Business Dashboard Example...")
    
    # Show business dashboard for Coffee Corner
    dashboard = qr_system.get_business_dashboard("coffee_corner_001")
    if dashboard["success"]:
        business_info = dashboard["business_info"]
        print(f"\n📊 {business_info['business_name']} Dashboard:")
        print(f"   Total Customers: {business_info['total_customers']}")
        print(f"   Total Stamps Given: {business_info['total_stamps_given']}")
        print(f"   Rewards Redeemed: {business_info['rewards_redeemed']}")
        print(f"   Prize Offered: {business_info['prize_offered']}")
        print(f"   Stamps Needed: {business_info['stamps_needed']}")
        print(f"   Min Purchase: ${business_info['minimum_purchase']}")
        
        if dashboard["recent_activity"]:
            print(f"\n📈 Recent Activity:")
            for activity in dashboard["recent_activity"][:3]:  # Show last 3
                status = "🎉 Reward earned!" if activity["reward_earned"] else "⏳ In progress"
                print(f"   • {activity['customer_username']}: {activity['current_stamps']}/{activity['stamps_needed']} {status}")
    
    print("\n4. Getting user's updated stamp cards...")
    user_cards = qr_system.get_user_stamp_cards("john_doe_123")
    if user_cards["success"]:
        print(f"📊 john_doe_123 has {len(user_cards['stamp_cards'])} stamp cards:")
        for card in user_cards["stamp_cards"]:
            status = "🎉 Ready to claim!" if card["claimed"] else "⏳ In progress"
            print(f"  • {card['business_name']}: {card['current_stamps']}/{card['stamps_needed']} {status}")
    else:
        print(f"❌ Error getting stamp cards: {user_cards['error']}")
    
    print(f"\n🌐 The same QR code file can be used at ALL businesses!")
    print(f"📄 QR Code file: {universal_qr['file_path']}")
    print("\n🏪 Business Features Added:")
    print("   • Business can scan customer QR codes")
    print("   • Automatic stamp addition to correct business")
    print("   • Business statistics tracking")
    print("   • Business dashboard with analytics")

if __name__ == "__main__":
    main()

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure AddRecord(User, Login, Password, SubscriberCode) Export
	
	Set = CreateRecordSet();
	Set.AdditionalProperties.Insert("Password", Password);
	Set.Filter.User.Set(User);
	Record = Set.Add();
	Record.User = User;
	Record.Login = Login;
	Record.SubscriberCode = SubscriberCode;
	Set.Write();
	
EndProcedure

Procedure DeleteRecord(User) Export
	
	Set = CreateRecordSet();
	Set.Filter.User.Set(User);
	Set.Write();
	
EndProcedure

// The owner of the secure storage.
// 
// Parameters:
//  User - CatalogRef.Users - User
// 
// Returns:
//  String
Function OwnerOfSecureStorage(User) Export
	
	UserID_1 = Common.ObjectAttributeValue(User, "IBUserID");
	Return StrTemplate("User_%1", UserID_1);
	
EndFunction
  
// Read the data.
// 
// Parameters:
//  User - CatalogRef.Users
// 
// Returns:
//  Structure:
// * Login - String
// * Password - String
// * SubscriberCode - Number
Function Read(User) Export
	
	Manager = CreateRecordManager();
	Manager.User = User;
	Manager.Read();
	
	Data = New Structure;
	Data.Insert("Login", Manager.Login);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = OwnerOfSecureStorage(User);
	Data.Insert("Password", String(Common.ReadDataFromSecureStorage(Owner)));
	Data.Insert("SubscriberCode", Manager.SubscriberCode);
	
	Return Data;
	
EndFunction
 
#EndRegion 
 
#EndIf
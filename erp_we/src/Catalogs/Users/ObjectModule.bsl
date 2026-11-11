///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#If Not MobileStandaloneServer Then

#Region Variables

// Object value before it is written (intended for the "OnWrite" event handler).
Var IsNew;
Var IBUserProcessingParameters; // Parameters to be populated when processing a user.

#EndRegion

// The Software Interface area.
//
// The object's programming interface is implemented through additional properties.
//
// User descriptionib - Structure with properties:
//   Action - String - "Write" or "Delete".
//      1. If Action = "Delete" no other properties are required. Deletion
//      will also be considered successful if the USERIB
//      is not found by the value of the User ID Attribute.
//      2. If Action = "Record", then
//      an information security user will be created or updated according to the specified properties. To prevent a user from being created
//      when not found, you need to insert the "Only update USERIB" property into the structure.
//
//   The program login is allowed - Undefined - calculate automatically:
//                            if the application login is prohibited, then it remains prohibited,
//                            otherwise it remains allowed, except when
//                            all types of authentication are set to False.
//                          - Boolean - if True, then set authentication as
//                            specified or saved in the values of the Attributes of the same name;
//                            if False, then remove all types of authentication from the information security user.
//                            If the property is not specified - direct installation of saved and
//                            valid authentication types (to support backward compatibility).
//
//   You need to change the password in the input - Boolean - changes the same-name checkbox of the user's card.
//                                  - Undefined - the checkbox does not change (similarly,
//                                        if the property is not specified).
//
//   Authenticationstandard, AuthenticationOpenID, AuthenticationOpenIDConnect,
//   Authenticationto Access token, AuthenticationOC - set the stored values
//      of the authentication types and the current values of the authentication
//      types, depending on the use of the input property in the program is resolved.
// 
//   Other properties.
//      The composition of the remaining properties is specified similarly to the composition of the parameter properties.
//      Updatable properties for the Users procedure.Set the property of the USERIB(),
//      except for the fullname property - set by Name.
//
//      To match an existing free information security user with a user in the Catalog
//      who is not matched with another existing information security user, you need to insert a property.
//      Unique identifier. If you specify the information security user ID that
//      is associated with the current user, nothing will change.
//
//   When performing the "Record" and "Delete" actions, the Attribute of the user ID of the
//   object is updated automatically, it should not be changed.
//
//   After performing the action, the following properties are inserted (updated) into the structure:
//   - The result of the action is a string containing one of the values:
//      - when the action "Record": "Useris added", "Useris changed", "USERIS deleted" and
 //         if the property "Only update the USERIB" is inserted, "The USERIB can be "skipped".
//      - when the action "Delete": "
//          Clears the addition of a non-existent userib", "There is no need to delete the userib"
//   - Unique identifier - Unique identifier of the information security user.
//
//   The user descriptionb is processed in a deceptive mode.Download = True.
//
// Administrator Creation - String - The property must be inserted with a non-empty string
//   in order to trigger the Administrator creation event after processing the structure of the user DESCRIPTIONI
//   when the created or modified user IB has administrator roles.
//   This is necessary to do related actions when creating an administrator, for example,
//   automatically add a user to the Administrators access group.
//
// The end of the region

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the locking of registers.
	If Common.FileInfobase() Then
		UsersInternal.LockRegistersBeforeWritingToFileInformationSystem(False);
	EndIf;
	// ACC:75-on
	
	// ACC:75-off - DataExchange.Load should be checked as needed after the infobase user is handled.
	UsersInternal.UserObjectBeforeWrite(ThisObject, IBUserProcessingParameters);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// ACC:75-off - DataExchange.Load should be checked as needed after the infobase user is handled.
	If DataExchange.Load And IBUserProcessingParameters <> Undefined Then
		UsersInternal.EndIBUserProcessing(
			ThisObject, IBUserProcessingParameters);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("NewUserGroup")
		And ValueIsFilled(AdditionalProperties.NewUserGroup) Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.UserGroups");
		LockItem.SetValue("Ref", AdditionalProperties.NewUserGroup);
		Block.Lock();
		
		GroupObject1 = AdditionalProperties.NewUserGroup.GetObject(); // CatalogObject.UserGroups
		GroupObject1.Content.Add().User = Ref;
		GroupObject1.Write();
	EndIf;
	
	// Updating the content of "All users" auto group.
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	UsersInternal.UpdateUserGroupCompositionUsage(Ref, ChangesInComposition);
	UsersInternal.UpdateAllUsersGroupComposition(Ref, ChangesInComposition);
	
	UsersInternal.EndIBUserProcessing(ThisObject,
		IBUserProcessingParameters);
	
	UsersInternal.AfterUserGroupsUpdate(ChangesInComposition);
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	// ACC:75-off - DataExchange.Load should be checked as needed after the infobase user is handled.
	UsersInternal.UserObjectBeforeDelete(ThisObject);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UsersInternal.UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	AdditionalProperties.Insert("CopyingValue", CopiedObject.Ref);
	
	IBUserID = Undefined;
	ServiceUserID = Undefined;
	Prepared = False;
	
	Properties = New Structure("ContactInformation");
	FillPropertyValues(Properties, ThisObject);
	If Properties.ContactInformation <> Undefined Then
		Properties.ContactInformation.Clear();
	EndIf;
	
	Comment = "";
	
EndProcedure

#EndRegion

#EndIf

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf
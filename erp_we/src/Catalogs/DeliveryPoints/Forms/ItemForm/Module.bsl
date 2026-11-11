//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	GoodsDelivery.SetAvailabilityOfDeliveryAddresses(Items);
	
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	NameAbbreviated = AbbreviatedPresentationOfAddress(
		Object.Address,
		Object.AddressValue,
		Not ValueIsFilled(Object.AddressID));
	
	UpdateNameSelectionList(NameAbbreviated);
	
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Async Procedure OnOpen(Cancel)
	
	
	SetAddressComment();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Async Procedure OverridableIdOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure AddressOnChange(Item)
	
	If IsBlankString(Object.Address) Then
		
		Object.FieldValueAddress = "";
		Object.AddressValue = "";
		Object.AddressID = "";
		
	Else
		
		FillInAddressFieldsByPresentation();
		
	EndIf;
	
	AddressOnChangeATServer();
	
EndProcedure

&AtClient
Procedure AddressStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("ProcessResultOfAddressSelection", ThisObject);
	GoodsDeliveryClient.OpenAddressSelectionForm(Item, Object.Address, Object.AddressValue, Notification);
	
EndProcedure

&AtClient
Procedure AddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.Address = "";
	Object.AddressValue = "";
	Object.FieldValueAddress = "";
	Object.AddressID = "";
	
	Items.Description.ChoiceList.Clear();
	
EndProcedure

&AtClient
Async Procedure DeliveryPointIDOnChange(Item)
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject);
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	UpdateAvailabilityOfAddressFields();
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfAddressFields()
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.Address.Name);
	ItemsNames.Add(Items.Owner.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemsNames,
		"ReadOnly",
		Object.MainPoint);
	
	Items.NotUsed.Enabled = Not Object.MainPoint;
	
EndProcedure

&AtServer
Procedure AddressOnChangeATServer()
	
	Object.AddressID = GoodsDeliveryLocalization.IdOfDeliveryPointAddress(Object.AddressValue);
	NameAbbreviated = AbbreviatedPresentationOfAddress(
		Object.Address,
		Object.AddressValue,
		Not ValueIsFilled(Object.AddressID));
	
	UpdateNameSelectionList(NameAbbreviated);
	
	If Not IsBlankString(NameAbbreviated) Then
		
		Object.Description = NameAbbreviated;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateNameSelectionList(NameAbbreviated)
	
	If Not IsBlankString(NameAbbreviated) Then
		
		ChoiceList = Items.Description.ChoiceList;
		
		If ChoiceList.Count() = 0 Then
			
			ListItem = ChoiceList.Add();
			
		Else
			
			ListItem = ChoiceList[0];
			
		EndIf;
		
		ListItem.Value = NameAbbreviated;
		
	EndIf;
	
EndProcedure


&AtServerNoContext
Function AbbreviatedPresentationOfAddress(Address, AddressValue, FreeForm = False)
	
	Abbreviated_Presentation = GoodsDeliveryLocalization.NameOfDeliveryPointAt(
		Address,
		AddressValue,
		FreeForm);
	
	Return Abbreviated_Presentation;
	
EndFunction

// Parameters:
//  Result - Undefined
//            - Structure:
//   * ContactInformation - String
//   * Value - String
//   * Presentation - String
//   * Comment - String
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure ProcessResultOfAddressSelection(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		
		// Transfer the data to the form
		Object.FieldValueAddress = Result.ContactInformation;
		Object.AddressValue = Result.Value;
		Object.Address = Result.Presentation;
		
		SetAddressComment(Result.Comment);
		
		AddressOnChangeATServer();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAddressFieldsByPresentation()
	
	GoodsDelivery.FillInAddressFieldsByPresentation(Object.Address, Object.AddressValue, Object.FieldValueAddress);
	
EndProcedure

// Parameters:
//  Result - Array of String
//  AdditionalParameters - Structure
//
&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array")
	   And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAddressComment(Comment = Undefined)
	
	If Comment = Undefined Then
		
		Comment = AddressComment(Object.AddressValue);
		
	EndIf;
	
	Items.Address.ExtendedTooltip.Title = Comment;
	If Not IsBlankString(Comment) Then
		
		Items.Address.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		
	Else
		
		Items.Address.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AddressComment(Val AddressValue)
	
	Comment = ContactsManager.ContactInformationComment(AddressValue);
	Return Comment;
	
EndFunction

#EndRegion
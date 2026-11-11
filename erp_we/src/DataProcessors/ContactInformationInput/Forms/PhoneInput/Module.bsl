///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// Form parameterization:
//
//      Title - String  - Form's title.
//      FieldValues - String - Serialized value of the contact information. 
//                                Or an empty string for a new input.
//      Presentation - String  - Address presentation (used for managing old data).
//      ContactInformationKind - CatalogRef.ContactInformationKinds, Structure - Details of the contact information
//                                to edit.
//      Comment - String - Optional text for the "Comment" field.
//
//      ReturnValueList - Boolean - Optional flag indicating if the return value of the "ContactInformation" field
//                                 has the "ValueList" data type (intended for compatibility).
//
//  Selection result:
//      Structure - Has the following fields:
//          * ContactInformation - String - XML data of the contact information.
//          * Presentation - String - Data presentation.
//          * Comment - String - Comment to the contact information.
//
// ------------------------------------------------------------------------------------------------- 

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReturnValueList", ReturnValueList);
	
	// Copying parameters to attributes.
	If TypeOf(Parameters.ContactInformationKind) = Type("CatalogRef.ContactInformationKinds") Then
		ContactInformationKind = Parameters.ContactInformationKind;
	EndIf;
	
	ContactInformationKindStructure1 = ContactsManagerInternal.ContactInformationKindStructure(Parameters.ContactInformationKind);
	ContactInformationType = ContactInformationKindStructure1.Type;  
	EnterNumberByMask = ContactInformationKindStructure1.EnterNumberByMask And (Not ValueIsFilled(Parameters.Presentation) 
		Or ContactsManagerInternal.PhoneNumberMatchesMask(Parameters.Presentation, ContactInformationKindStructure1.PhoneNumberMask)); 
	
	CheckValidity = ContactInformationKindStructure1.CheckValidity;
	Title = ?(IsBlankString(Parameters.Title), String(ContactInformationKind), Parameters.Title);
	IsNew = False;
	
	FieldValues = DetermineContactInformationValue(Parameters);
	
	If Not EnterNumberByMask And Metadata.DataProcessors.Find("AdvancedContactInformationInput") <> Undefined Then
		ModuleAdvancedContactInformationInput = Common.CommonModule("DataProcessors.AdvancedContactInformationInput");
		TipsWhenEnteringAPhoneNumber = ModuleAdvancedContactInformationInput.TipsWhenEnteringAPhoneNumber();
		Items.CountryCode.InputHint = TipsWhenEnteringAPhoneNumber.CountryCode;
		Items.CityCode.InputHint = TipsWhenEnteringAPhoneNumber.CityCode;
		Items.PhoneNumber.InputHint = TipsWhenEnteringAPhoneNumber.PhoneNumber;
		
		UseAdditionalChecks = True;
		
	EndIf;
	
	If IsBlankString(FieldValues) Then
		Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
		IsNew = True;
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(FieldValues) Then
		Data = ContactsManagerInternal.JSONToContactInformationByFields(FieldValues, Enums.ContactInformationTypes.Phone);
	Else
		
		If ContactsManagerClientServer.IsXMLContactInformation(FieldValues) Then
			
			ReadResults     = New Structure;
			ContactInformation = Undefined;
			
			ContactsManagerLocalization.OnConvertContactInformationFromXML(FieldValues, ContactInformation, ContactInformationType, ReadResults);
			If ReadResults.Property("ErrorText") Then
				// Recognition errors. A warning must be displayed when opening the form.
				WarningTextOnOpen = ReadResults.ErrorText;
				ContactInformation.Presentation = Parameters.Presentation;
			EndIf;
				
		Else
			ContactInformation = Undefined;
			If ContactInformationType = Enums.ContactInformationTypes.Phone Then
				ContactsManagerLocalization.OnConvertPhoneToXDTOObject(FieldValues, 
					ContactInformation, Parameters.Presentation, ContactInformationType);
					
			Else
				ContactsManagerLocalization.OnConvertFaxToXDTOObject(FieldValues, 
					ContactInformation, Parameters.Presentation, ContactInformationType);
				
			EndIf;
		EndIf;
			
		If ContactInformation <> Undefined Then
			Data = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, ContactInformationType);
		Else
			Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
		EndIf;
			
	EndIf;
		
	ContactInformationAttibutesValues(Data); 
	
	Items.PhoneNumberByMask.Visible = EnterNumberByMask;
	Items.PhoneNumberByMask.Mask = ContactInformationKindStructure1.PhoneNumberMask;	
	Items.PhoneFieldsGroup.Visible = Not EnterNumberByMask;
	Items.PhoneExtension.Visible = ContactInformationKindStructure1.PhoneWithExtensionNumber;
	Items.ClearPhone.Enabled = Not Parameters.ReadOnly;
	
	If Not EnterNumberByMask Then
		Codes = Common.CommonSettingsStorageLoad("DataProcessor.ContactInformationInput.Form.PhoneInput", "CountryAndCityCodes");
		If TypeOf(Codes) = Type("Structure") Then
			If IsNew Then
				Codes.Property("CountryCode", CountryCode);
				Codes.Property("CityCode", CityCode);
			EndIf;
			
			If Codes.Property("CityCodesList") Then
				Items.CityCode.ChoiceList.LoadValues(Codes.CityCodesList);
			EndIf;
		EndIf;
		
		If ContactInformationKindStructure1.StoreChangeHistory Then
			If Parameters.ContactInformationAdditionalAttributesDetails <> Undefined Then
				For Each CIRow In Parameters.ContactInformationAdditionalAttributesDetails Do
					NewRow = ContactInformationAdditionalAttributesDetails.Add();
					FillPropertyValues(NewRow, CIRow);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If Common.IsMobileClient() Then
		
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		
		CommonClientServer.SetFormItemProperty(Items, "Presentation", "InputHint", NStr("vi = 'Trình bày';
																						|ru = 'Представление';
																						|en = 'Presentation'; fa = 'نمایش';
																						|it = 'Visualizzazione';
																						|pl = 'Presentation';
																						|tr = 'Sunum'"));
		CommonClientServer.SetFormItemProperty(Items, "OkCommand", "Picture", PictureLib.WriteAndClose);
		CommonClientServer.SetFormItemProperty(Items, "OkCommand", "Representation", ButtonRepresentation.Picture);
		CommonClientServer.SetFormItemProperty(Items, "Cancel", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items, "CountryCode", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "CityCode", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "PhoneNumber", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "PhoneExtension", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "PhoneNumberByMask", "TitleLocation", FormItemTitleLocation.Left);  
		
		If Items.CityCode.ChoiceList.Count() < 2 Then
			
			Items.CityCode.DropListButton = Undefined;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(WarningTextOnOpen) Then
		AttachIdleHandler("Attachable_WarnAfterOpenForm", 0.1, True);
	EndIf;
	
	If ValueIsFilled(CityCode) Then
		CurrentItem = Items.CityCode;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ConfirmAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountryCodeOnChange(Item)
	
	FillPhonePresentation();
	
EndProcedure

&AtClient
Procedure CityCodeOnChange(Item)
	
	If UseAdditionalChecks Then
	
		ModuleAddressManagerClient = CommonClient.CommonModule("AddressManagerClient");
		ModuleAddressManagerClient.ShowHintAboutCorrectnessOfCountryAndCityCodes(CountryCode, CityCode);
		
	EndIf;
	
	FillPhonePresentation();
EndProcedure

&AtClient
Procedure PhoneNumberOnChange(Item)
	
	FillPhonePresentation();
	
EndProcedure

&AtClient
Procedure PhoneExtensionOnChange(Item)
	
	FillPhonePresentation();
	
EndProcedure

&AtClient
Procedure PhoneNumberByMaskOnChange(Item)

	Modified = True;
	Presentation = PhoneNumberByMask;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	ConfirmAndClose();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure ClearPhone(Command)
	
	ClearPhoneServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Attachable_WarnAfterOpenForm()
	
	CommonClient.MessageToUser(WarningTextOnOpen);
	
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	// When unmodified, it functions as "cancel".
	
	If Modified Then
		
		HasFillingErrors = False;
		// Determining whether validation is required.
		If CheckValidity Then
			
			ModuleAddressManagerClient = Undefined;
			If UseAdditionalChecks Then
				ModuleAddressManagerClient = CommonClient.CommonModule("AddressManagerClient");
			EndIf;
			
			Phonefields = ContactsManagerClientServer.PhoneFieldStructure();
			Phonefields.CityCode     = CityCode;
			Phonefields.CountryCode     = CountryCode;    
			Phonefields.PhoneNumber = PhoneNumber;
			Phonefields.Presentation = Presentation;
			Phonefields.PhoneExtension    = PhoneExtension;
			Phonefields.Comment   = Comment;  
			If EnterNumberByMask Then
				Phonefields.PhoneNumber = PhoneNumberByMask;
			EndIf;	
			
			ErrorList = ContactsManagerClientServer.PhoneFillingErrors(Phonefields, ModuleAddressManagerClient);
			
			HasFillingErrors = ErrorList.Count() > 0;
		EndIf;
		If HasFillingErrors Then
			NotifyFillErrors(ErrorList);
			Return;
		EndIf;
		
		Result = SelectionResult();
	
		ClearModifiedOnChoice();
		NotifyChoice(Result);
		
	ElsIf Comment <> CommentCopy Then
		// Only the comment was modified, attempting to revert.
		Result = CommentChoiceOnlyResult();
		
		ClearModifiedOnChoice();
		NotifyChoice(Result);
		
	Else
		Result = Undefined;
		
	EndIf;
	
	If (ModalMode Or CloseOnChoice) And IsOpen() Then
		ClearModifiedOnChoice();
		Close(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearModifiedOnChoice()
	
	Modified = False;
	CommentCopy   = Comment;
	
EndProcedure

&AtServer
Function SelectionResult()
	
	Result = New Structure();
	
	ChoiceList = Items.CityCode.ChoiceList;
	ListItem = ChoiceList.FindByValue(CityCode);
	If ListItem = Undefined Then
		ChoiceList.Insert(0, CityCode);
		If ChoiceList.Count() > 10 Then
			ChoiceList.Delete(10);
		EndIf;
	Else
		IndexOf = ChoiceList.IndexOf(ListItem);
		If IndexOf <> 0 Then
			ChoiceList.Move(IndexOf, -IndexOf);
		EndIf;
	EndIf;
	
	Codes = New Structure("CountryCode, CityCode, CityCodesList", CountryCode, CityCode, ChoiceList.UnloadValues());
	Common.CommonSettingsStorageSave("DataProcessor.ContactInformationInput.Form.PhoneInput", "CountryAndCityCodes", Codes, NStr("vi = 'Mã quốc gia và thành phố';
																																|ru = 'Коды страны и города';
																																|en = 'Codes of country and city.'; fa = 'Codes of country and city.';
																																|it = 'I prefissi di stato e città';
																																|pl = 'Kody kraju i miasta';
																																|tr = 'Ülke ve şehir kodu'"));
	
	ContactInformation = ContactInformationByAttributesValues();
	
	ChoiceData = ContactsManagerInternal.ToJSONStringStructure(ContactInformation);
	
	Result.Insert("Kind", ContactInformationKind);
	Result.Insert("Type", ContactInformationType);
	Result.Insert("ContactInformation", ContactsManager.ContactInformationToXML(ChoiceData, ContactInformation.Value, ContactInformationType));
	Result.Insert("Value", ChoiceData);
	Result.Insert("Presentation", ContactInformation.Value);
	Result.Insert("Comment", ContactInformation.Comment);
	Result.Insert("AsHyperlink", False);
	Result.Insert("ContactInformationAdditionalAttributesDetails",
		ContactInformationAdditionalAttributesDetails);
	
	Return Result
EndFunction

&AtServer
Function CommentChoiceOnlyResult()
	
	ContactInformationValue = DetermineContactInformationValue(Parameters);
	If IsBlankString(ContactInformationValue) Then
		
			If ContactInformationType = Enums.ContactInformationTypes.Phone Then
				ContactsManagerLocalization.OnConvertPhoneToXDTOObject("", ContactInformationValue, "", ContactInformationType);
			Else
				ContactsManagerLocalization.OnConvertFaxToXDTOObject("", ContactInformationValue, "", ContactInformationType);
			EndIf;
			
			ContactsManager.SetContactInformationComment(ContactInformationValue, Comment);
			ContactInformationValue = ContactsManager.ContactInformationToXML(ContactInformationValue);
			
	ElsIf ContactsManagerClientServer.IsXMLContactInformation(ContactInformationValue) Then
		ContactsManager.SetContactInformationComment(ContactInformationValue, Comment);
	EndIf;
	
	Return New Structure("ContactInformation, Presentation, Comment",
		ContactInformationValue, Parameters.Presentation, Comment);
EndFunction

// Fills in form attributes based on XTDO object of the Contact information type.
&AtServer
Procedure ContactInformationAttibutesValues(InformationToEdit)
	
	// Common attributes.
	Presentation = InformationToEdit.Value;
	Comment   = InformationToEdit.Comment;
	
	// Comment copy used to analyze changes.
	CommentCopy = Comment;
	
	If EnterNumberByMask Then 
		PhoneNumberByMask = InformationToEdit.Value;	
	Else	
		CountryCode     = InformationToEdit.CountryCode;
		CityCode     = InformationToEdit.AreaCode;
		PhoneNumber = InformationToEdit.Number;
		PhoneExtension    = InformationToEdit.ExtNumber;
	EndIf;
			
EndProcedure

// Returns an XTDO object of the Contact information type based on attribute values.
&AtServer
Function ContactInformationByAttributesValues()
	
	Result = ContactsManagerClientServer.NewContactInformationDetails(ContactInformationType);
	
	If EnterNumberByMask Then   
		ContactInformation = ContactsManagerInternal.ContactsByPresentation(PhoneNumberByMask, ContactInformationKind);
		Result.CountryCode = ContactInformation.CountryCode;
		Result.AreaCode    = ContactInformation.AreaCode;
		Result.Number      = ContactInformation.Number;
		Result.ExtNumber   = ContactInformation.ExtNumber;
		Result.Value       = PhoneNumberByMask;		
	Else	
		Result.CountryCode = CountryCode;
		Result.AreaCode    = CityCode;
		Result.Number      = PhoneNumber;
		Result.ExtNumber   = PhoneExtension;
		Result.Value       = ContactsManagerClientServer.GeneratePhonePresentation(CountryCode, CityCode, PhoneNumber, PhoneExtension, "");
	EndIf;    
	
	Result.Comment     = Comment;
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillPhonePresentation()
	
	AttachIdleHandler("FillPhonePresentationNow", 0.1, True);
	
EndProcedure

&AtClient
Procedure FillPhonePresentationNow()
	
	Presentation = ContactsManagerClientServer.GeneratePhonePresentation(CountryCode, 
		CityCode, PhoneNumber, PhoneExtension, "");
	
EndProcedure

// Notifies of any filling errors based on PhoneFillingErrorsServer function results.
&AtClient
Procedure NotifyFillErrors(ErrorList)
	
	If ErrorList.Count()=0 Then
		ShowMessageBox(, NStr("vi = 'Đã nhập số điện thoại chính xác.';
								|ru = 'Телефон введен корректно.';
								|en = 'The phone number is valid.'; fa = 'The phone number is valid.';
								|it = 'Il numero di telefono è inserito in modo corretto.';
								|pl = 'Telefon został wprowadzony poprawnie.';
								|tr = 'Geçerli telefon numarası girildi.'"));
		Return;
	EndIf;
	
	ClearMessages();
	
	// Values are XPaths. Presentations store error descriptions.
	For Each Item In ErrorList Do
		CommonClient.MessageToUser(Item.Presentation,,,
		FormDataPathByXPath(Item.Value));
	EndDo;
	
EndProcedure    

&AtClient 
Function FormDataPathByXPath(XPath) 
	Return XPath;
EndFunction

&AtServer
Procedure ClearPhoneServer()
	CountryCode     = "";
	CityCode     = "";
	PhoneNumber = "";
	PhoneExtension    = "";
	Comment   = "";
	Presentation = ""; 
	PhoneNumberByMask = "";
	
	Modified = True;
EndProcedure

&AtServer
Function DetermineContactInformationValue(Var_Parameters)
	
	If ValueIsFilled(Var_Parameters.Value) Then
		FieldValues = Var_Parameters.Value;
	Else
		FieldValues = Var_Parameters.FieldValues;
	EndIf;
	Return FieldValues;

EndFunction

#EndRegion

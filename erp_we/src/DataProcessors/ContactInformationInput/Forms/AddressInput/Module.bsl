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
//      ContactInformationKind - CatalogRef.ContactInformationKinds, Structure - Details of the contact information to edit.
//                                Comment - String - Optional text for the "Comment" field.
//      ReturnValueList - Boolean - Optional flag indicating if the return value of the "ContactInformation" field
//
//      has the "ValueList" data type (intended for compatibility).
//                                 Selection result:
//
//  Structure - Has the following fields:
//      * ContactInformation - String - XML data of the contact information.
//          * Presentation - String - Data presentation.
//          * Comment - String - Comment to the contact information.
//          * EnteredInFreeFormat - Boolean - Arbitrary input flag.
//          
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
		If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	// Form settings.
	Parameters.Property("ReturnValueList", ReturnValueList);
	MainCountry           = MainCountry();
	CIKind  = ContactsManagerInternal.ContactInformationKindStructure(Parameters.ContactInformationKind);  // See ContactsManagerInternal.ContactInformationKindStructure
	ContactInformationKind = CIKind;
	OnCreateAtServerStoreChangeHistory();
	
	Title = ?(IsBlankString(Parameters.Title), String(CIKind.Ref), Parameters.Title);
	
	HideObsoleteAddresses  = ContactInformationKind.HideObsoleteAddresses;
	ContactInformationType     = ContactInformationKind.Type;
	
	// Attempting to fill data based on parameter values.
	ContactInformationValue = DefineAddressValue(Parameters);
	
	If IsBlankString(ContactInformationValue) Then
		LocalityDetailed = ContactsManager.NewContactInformationDetails(Enums.ContactInformationTypes.Address); // New address.
		
		If ValueIsFilled(Parameters.Presentation) Then
			LocalityDetailed.value       = Parameters.Presentation;
			LocalityDetailed.addressType = ContactsManagerClientServer.CustomFormatAddress();
		Else
			LocalityDetailed.addressType = ContactsManagerClientServer.ForeignAddress();
		EndIf;
		
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(ContactInformationValue) Then
		AddressData = ContactsManagerInternal.JSONToContactInformationByFields(ContactInformationValue, Enums.ContactInformationTypes.Address);
		LocalityDetailed = PrepareAddressForInput(AddressData);
	EndIf;
	
	FillInPredefinedAddressOptions();
	SetAttributesValueByContactInformation(LocalityDetailed);
	
	AllowAddressInputInFreeForm = ContactsManagerClientServer.IsAddressInFreeForm(LocalityDetailed.addressType);
	
	If ValueIsFilled(LocalityDetailed.Comment) Then
		Items.PagesMain.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.CommentPage.Picture = CommonClientServer.CommentPicture(Comment);
	Else
		Items.PagesMain.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	SetFormUsageKey();
	Items.FormClearAddress.Enabled = Not Parameters.ReadOnly;
	Items.CommandAddGroup.Visible = Not Parameters.ReadOnly;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(WarningTextOnOpen) Then
		CommonClient.MessageToUser(WarningTextOnOpen,, WarningFieldOnOpen);
	EndIf;
	
	DisplayAddressFields(ContactsManagerClientServer.IsAddressInFreeForm(LocalityDetailed.addressType));

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ConfirmAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountryOnChange(Item)
	
	If ContactsManagerClientServer.IsAddressInFreeForm(LocalityDetailed.addressType) Then
		AddressParts = StrSplit(LocalityDetailed.value, ",", True);
		CountryBeforeChange = LocalityDetailed.country;
		For Position = 0 To AddressParts.UBound() Do
			If StrCompare(TrimAll(AddressParts[Position]), CountryBeforeChange) = 0 Then
				PositionStart = StrFind(Upper(AddressParts[Position]), Upper(CountryBeforeChange));
				AddressParts[Position] = Left(AddressParts[Position], PositionStart - 1) 
					+ String(Country) + Mid(AddressParts[Position], PositionStart + StrLen(CountryBeforeChange));
			EndIf;
		EndDo;
		AddressPresentation =  StrConcat(AddressParts, ",");
		
		LocalityDetailed.admLevels = New Array;
		LocalityDetailed.country   = TrimAll(Country);
		LocalityDetailed.value     = AddressPresentation;
		
	Else
		DisplayFieldsByAddressType();
	EndIf;
	
EndProcedure

&AtClient
Procedure CountryClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CommentOnChange(Item)
	
	LocalityDetailed.Comment = Comment;
	AttachIdleHandler("SetCommentIcon", 0.1, True);
	
EndProcedure

&AtClient
Procedure ForeignAddressPresentationOnChange(Item)
	
	LocalityDetailed.value = AddressPresentation;
	
EndProcedure

&AtClient
Procedure AddressOnDateAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	If StrCompare(Text, TheBeginningOfTheAccounting()) = 0 Or IsBlankString(Text) Then
		Items.AddressOnDate.EditFormat = "";
	EndIf;
EndProcedure

&AtClient
Procedure AddressOnDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not EnterNewAddress Then
		
		Filter = New Structure("Kind", ContactInformationKindDetails(ThisObject).Ref);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		Result = DefineValidDate(AddressOnDate, FoundRows);
		
		If Result.CurrentRow <> Undefined Then
			Type = Result.CurrentRow.Type;
			AddressValidFrom = Result.ValidFrom;
			LocalityDetailed = AddressWithHistory(Result.CurrentRow.Value);
		Else
			Type = PredefinedValue("Enum.ContactInformationTypes.Address");
			AddressValidFrom = AddressOnDate;
			LocalityDetailed = ContactsManagerClientServer.NewContactInformationDetails(Type);
		EndIf;
		
		
		
		If ValueIsFilled(Result.ValidTo) Then
			TextHistoricalAddress = " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'có hiệu lực đến %1';
																										|ru = 'действует по %1';
																										|en = 'valid until %1'; fa = 'valid until %1';
																										|it = 'in vigore al %1';
																										|pl = 'aktuylny do %1';
																										|tr = '%1 kadar geçerli'"), Format(Result.ValidTo - 10, "DLF=DD"));
		Else
			TextHistoricalAddress = NStr("vi = 'có hiệu lực đến hết thời gian này.';
										|ru = 'действует по настоящее время.';
										|en = 'valid as of today.'; fa = 'valid as of today.';
										|it = 'valido fino ad oggi.';
										|pl = 'ważne do chwili obecnej.';
										|tr = 'bugün itibariyle geçerli.'");
		EndIf;
		Items.AddressStillValid.Title = TextHistoricalAddress;
	Else
		AddressValidFrom = AddressOnDate;
	EndIf;
	
	TextOfAccountingStart = TheBeginningOfTheAccounting();
	Items.AddressOnDate.EditFormat = ?(ValueIsFilled(AddressOnDate), "", "DF='""" + TextOfAccountingStart  + """'");
	
EndProcedure

&AtServerNoContext
Function AddressWithHistory(FieldValues)
	
	Return ContactsManagerInternal.JSONToContactInformationByFields(FieldValues, Enums.ContactInformationTypes.Address);
	
EndFunction


&AtClient
Procedure Address1OnChange(Item)
	LocalityDetailed.street = Street;
	UpdateAddressPresentation();
EndProcedure

&AtClient
Procedure Address2OnChange(Item)
	LocalityDetailed.houseNumber = AdditionalInformation;
	UpdateAddressPresentation();
EndProcedure

&AtClient
Procedure CityOnChange(Item)
	
	LocalityDetailed.city = City;
	UpdateAddressPresentation();

EndProcedure

&AtClient
Procedure StateOnChange(Item)
	LocalityDetailed.area = State;
	UpdateAddressPresentation();
EndProcedure

&AtClient
Procedure IndexOfOnChange(Item)
	LocalityDetailed.ZIPcode = PostalCode;
	UpdateAddressPresentation();
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
Procedure ClearAddress(Command)
	
	ClearAddressClient();
	UpdateAddressPresentation();
	
EndProcedure

&AtClient
Procedure CopyAddressToClipboard(Command)
	ContactsManagerClient.PutTextInClipboard(AddressPresentation);
EndProcedure

&AtClient
Procedure ChangeHistory(Command)
	
	AdditionalParameters = New Structure;
	
	AdditionalAttributesDetails = ContactInformationAdditionalAttributesDetails;
	ContactInformationList = FillContactInformationList( ContactInformationKindDetails(ThisObject).Ref, AdditionalAttributesDetails);
	
	FormParameters = New Structure("ContactInformationList", ContactInformationList);
	FormParameters.Insert("ContactInformationKind",  ContactInformationKindDetails(ThisObject).Ref);
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("FromAddressEntryForm", True);
	FormParameters.Insert("ValidFrom", AddressOnDate);
	
	ClosingNotification = New CallbackDescription("AfterClosingHistoryForm", ThisObject, AdditionalParameters);
	OpenForm("DataProcessor.ContactInformationInput.Form.ContactInformationHistory", FormParameters, ThisObject,,,, ClosingNotification);
	
EndProcedure

&AtClient
Procedure AddComment(Command)
	Items.PagesMain.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Items.PagesMain.CurrentPage = Items.CommentPage;
EndProcedure

&AtClient
Procedure CustomFormatAddress(Command)
	
	If ContactsManagerClientServer.IsAddressInFreeForm(LocalityDetailed.addressType) Then
		
		AllowAddressInputInFreeForm = False;
		
		FieldsSet = StrSplit(LocalityDetailed.value, ",");
		For FieldNumber = 0 To FieldsSet.UBound() Do
			FieldsSet[FieldNumber] = TrimAll(FieldsSet[FieldNumber]);
		EndDo;
		
		CountryFromAddress = DetermineWorldCountry(FieldsSet);
		
		If ValueIsFilled(CountryFromAddress.Description) Then
			LocalityDetailed.country     = CountryFromAddress.Description;
			LocalityDetailed.countryCode = CountryFromAddress.CountryCode;
			Country                              = CountryFromAddress.Ref;
		EndIf;

		OrdinalListOfFields = New Array;
		
		If TypeOf(LocalityDetailed.admLevels) = Type("Array") 
		   And LocalityDetailed.admLevels.Count() > 0 Then
			FieldsOrder = LocalityDetailed.admLevels;
		Else
			FieldsOrder = FieldsInAddressOrder(ContactInformationKind.IncludeCountryInPresentation);
		EndIf;
		
		If ValueIsFilled(CountryFromAddress.Description) Then
			For FieldSeqNumber = 0 To FieldsSet.UBound() Do
				If StrCompare(FieldsSet[FieldSeqNumber], CountryFromAddress.Description) = 0 Then
					FieldsSet.Delete(FieldSeqNumber);
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		ClearSettlementFields();
		
		For FieldSeqNumber = 0 To FieldsOrder.UBound() Do
			
			If FieldsSet.Count() = 0 Then
				Break;
			ElsIf FieldSeqNumber = FieldsOrder.UBound() Then
				LocalityDetailed[FieldsOrder[FieldSeqNumber]] = TrimAll(StrConcat(FieldsSet, ", "));
				OrdinalListOfFields.Add(FieldsOrder[FieldSeqNumber]);
			Else
				
				If StrCompare(FieldsOrder[FieldSeqNumber], "country") <> 0 Then
					LocalityDetailed[FieldsOrder[FieldSeqNumber]] = FieldsSet[0];
					OrdinalListOfFields.Add(FieldsOrder[FieldSeqNumber]);
					FieldsSet.Delete(0);
				ElsIf ContactInformationKind.IncludeCountryInPresentation Then
					OrdinalListOfFields.Add(FieldsOrder[FieldSeqNumber]);
				EndIf;
				
			EndIf;

		EndDo;
			
		LocalityDetailed.admLevels = OrdinalListOfFields;
			
		LocalityDetailed.addressType = ContactsManagerClientServer.ForeignAddress();
		DisplayAddressFields(False);
		UpdateAddressPresentation();
		
	Else
		
		Items.CustomFormatAddress.Check   = True;
		LocalityDetailed.addressType     = ContactsManagerClientServer.CustomFormatAddress();
		AllowAddressInputInFreeForm      = True;
		
		ClearSettlementFields();
		If IsBlankString(LocalityDetailed.value) Then
			LocalityDetailed.admLevels = New Array;
		EndIf;
		
		DisplayAddressFields(True);
		
	EndIf;
	
	Street                    = LocalityDetailed.street;
	AdditionalInformation = LocalityDetailed.houseNumber;
	City                    = LocalityDetailed.city;
	State                   = LocalityDetailed.area;
	PostalCode           = LocalityDetailed.ZIPCode;

EndProcedure


&AtServerNoContext
Function DetermineWorldCountry(FieldsSet)
	
	Return ContactsManagerInternal.DetermineWorldCountry(FieldsSet);
	
EndFunction

#EndRegion

#Region Private

&AtClient
Function FieldsInAddressOrder(IncludeCountryInPresentation)

	LevelsInAddressOrder = New Array;
	
	ContactsManagerClientLocalization.OnDefineAddressFieldsOrder(LevelsInAddressOrder, Country, IncludeCountryInPresentation);
	
	If LevelsInAddressOrder.Count() = 0 Then
		DefaultFieldsOrder(LevelsInAddressOrder, IncludeCountryInPresentation);
	EndIf;
	
	Return LevelsInAddressOrder;
	
EndFunction

&AtClient
Procedure ClearSettlementFields()
	LocalityDetailed.street      = "";
	LocalityDetailed.houseNumber = "";
	LocalityDetailed.city        = "";
	LocalityDetailed.area        = "";
	LocalityDetailed.ZIPCode     = "";
EndProcedure

&AtClient
Procedure UpdateAddressPresentation()
	
	FillAddressPresentation(LocalityDetailed, ContactInformationKind.IncludeCountryInPresentation);
	AddressPresentation = LocalityDetailed.value;
		
EndProcedure

&AtClient
Procedure DefaultFieldsOrder(LevelsInAddressOrder, IncludeCountryInPresentation)
	
	If IncludeCountryInPresentation Then
		LevelsInAddressOrder.Add("country");
	EndIf;

	LevelsInAddressOrder.Add("zipCode");
	LevelsInAddressOrder.Add("area");
	LevelsInAddressOrder.Add("city");
	LevelsInAddressOrder.Add("street");
	LevelsInAddressOrder.Add("houseNumber");
EndProcedure

&AtClient
Function PresentationOfAddressInFreeForm(Val Address, Val IncludeCountryInPresentation)
	
	If IncludeCountryInPresentation And Address.Property("country") And Not IsBlankString(Address.country) Then
		AddressParts = StrSplit(Address.value, ",");
		If ValueIsFilled(Address.value) And StrCompare(AddressParts[0], Address.country) = 0 Then
			AddressParts.Delete(0);
			Address.Value = StrConcat(AddressParts, ",");
		EndIf;
		
	EndIf;
	
	Return Address.Value;
	
EndFunction

&AtClient
Procedure SetCommentIcon()
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Comment);
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Modified Then // When unmodified, it functions as "cancel".
		Context = New Structure("ContactInformationKind, LocalityDetailed, MainCountry, Country");
		FillPropertyValues(Context, ThisObject);
		Result = FlagUpdateSelectionResults(Context, ReturnValueList);
		
		// Reading contact information kind flags again.
		ContactInformationKind = Context.ContactInformationKind;
		
		Result = Result.ChoiceData;
		If ContactInformationKind.StoreChangeHistory Then
			ProcessContactInformationWithHistory(Result);
		EndIf;
		
		If TypeOf(Result) = Type("Structure") Then
			Result.Insert("ContactInformationAdditionalAttributesDetails", ContactInformationAdditionalAttributesDetails);
		EndIf;
		
		ClearModifiedOnChoice();
#If WebClient Then
		CloseFlag = CloseOnChoice;
		CloseOnChoice = False;
		NotifyChoice(Result);
		CloseOnChoice = CloseFlag;
#Else
		NotifyChoice(Result);
#EndIf
		SaveFormState();
		
	ElsIf Comment <> CommentCopy Then
		// Only the comment was modified, attempting to revert.
		Result = CommentChoiceOnlyResult(Parameters.FieldValues, Parameters.Presentation, Comment);
		Result = Result.ChoiceData;
		
		ClearModifiedOnChoice();
#If WebClient Then
		CloseFlag = CloseOnChoice;
		CloseOnChoice = False;
		NotifyChoice(Result);
		CloseOnChoice = CloseFlag;
#Else
		NotifyChoice(Result);
#EndIf
		SaveFormState();
		
	Else
		Result = Undefined;
	EndIf;
	
	If (ModalMode Or CloseOnChoice) And IsOpen() Then
		ClearModifiedOnChoice();
		SaveFormState();
		Close(Result);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessContactInformationWithHistory(Result)
	
	Result.Insert("ValidFrom", ?(EnterNewAddress, AddressOnDate, AddressValidFrom));
	AttributeName = "";
	Filter = New Structure("Kind", Result.Kind);
	
	ValidAddressString = Undefined;
	DateChanged         = True;
	CurrentAddressDate        = CommonClient.SessionDate();
	Delta                   = AddressOnDate - CurrentAddressDate;
	MinDelta        = ?(Delta > 0, Delta, -Delta);
	FoundRows          = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	For Each FoundRow In FoundRows Do
		If ValueIsFilled(FoundRow.AttributeName) Then
			AttributeName = FoundRow.AttributeName;
		EndIf;
		If FoundRow.ValidFrom = AddressOnDate Then
			DateChanged = False;
			ValidAddressString = FoundRow;
			Break;
		EndIf;
		
		Delta = CurrentAddressDate - FoundRow.ValidFrom;
		Delta = ?(Delta > 0, Delta, -Delta);
		If Delta <= MinDelta Then
			MinDelta = Delta;
			ValidAddressString = FoundRow;
		EndIf;
	EndDo;
	
	If DateChanged Then
		
		Filter = New Structure("ValidFrom, Kind", AddressValidFrom, Result.Kind);
		StringsWithAddress = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		
		EditableAddressPresentation = ?(StringsWithAddress.Count() > 0, StringsWithAddress[0].Presentation, ""); 
		CommentPresentation          = ?(StringsWithAddress.Count() > 0, StringsWithAddress[0].Comment,   "");
		AddRow = StrCompare(Result.Presentation, EditableAddressPresentation) <> 0
					 Or StrCompare(Result.Comment, CommentPresentation) <> 0;
		
		If AddRow Then
			NewContactInformation = ContactInformationAdditionalAttributesDetails.Add();
			FillPropertyValues(NewContactInformation, Result);
			NewContactInformation.Value                = Result.Value;
			NewContactInformation.ValidFrom              = AddressOnDate;
			NewContactInformation.StoreChangeHistory = True;
			If ValidAddressString = Undefined Then
				Filter = New Structure("IsHistoricalContactInformation, Kind", False, Result.Kind);
				FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
				For Each FoundRow In FoundRows Do
					FoundRow.IsHistoricalContactInformation = True;
					FoundRow.AttributeName = "";
				EndDo;
				NewContactInformation.AttributeName = AttributeName;
				NewContactInformation.IsHistoricalContactInformation = False;
			Else
				NewContactInformation.IsHistoricalContactInformation = True;
				Result.Presentation                = ValidAddressString.Presentation;
				Result.Value = ValidAddressString.Value;
			EndIf;
		ElsIf ValidAddressString <> Undefined
				And StrCompare(Result.Comment, ValidAddressString.Comment) <> 0 
				And StringsWithAddress.Count() > 0 Then
					// Only the comment is modified.
					StringsWithAddress[0].Comment = Result.Comment;
		EndIf;
	Else
		If StrCompare(Result.Presentation, ValidAddressString.Presentation) <> 0
			Or StrCompare(Result.Comment, ValidAddressString.Comment) <> 0 Then
				FillPropertyValues(ValidAddressString, Result);
				ValidAddressString.Value                            = Result.Value;
				ValidAddressString.AttributeName                        = AttributeName;
				ValidAddressString.IsHistoricalContactInformation = False;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure AfterClosingHistoryForm(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	EnterNewAddress = ?(Result.Property("EnterNewAddress"), Result.EnterNewAddress, False);
	If EnterNewAddress Then
		AddressValidFrom = AddressOnDate;
		AddressOnDate = Result.CurrentAddress;
		LocalityDetailed = ContactsManagerClientServer.NewContactInformationDetails(PredefinedValue("Enum.ContactInformationTypes.Address"));
		If Not AllowAddressInputInFreeForm Then
			LocalityDetailed.addressType = ContactsManagerClientServer.ForeignAddress();
		EndIf;
		ClearAddressFieldsOnForm();
	Else
		Filter = New Structure("Kind",  ContactInformationKindDetails(ThisObject).Ref);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		
		AttributeName = "";
		For Each ContactInformationRow In FoundRows Do
			If Not ContactInformationRow.IsHistoricalContactInformation Then
				AttributeName = ContactInformationRow.AttributeName;
			EndIf;
			ContactInformationAdditionalAttributesDetails.Delete(ContactInformationRow);
		EndDo;
		
		For Each ContactInformationRow In Result.History Do
			RowData = ContactInformationAdditionalAttributesDetails.Add();
			FillPropertyValues(RowData, ContactInformationRow);
			If Not ContactInformationRow.IsHistoricalContactInformation Then
				RowData.AttributeName = AttributeName;
			EndIf;
			If BegOfDay(Result.CurrentAddress) = BegOfDay(ContactInformationRow.ValidFrom) Then
				AddressOnDate = Result.CurrentAddress;
				LocalityDetailed = JSONStringToStructure(ContactInformationRow.Value);
				
			EndIf;
		EndDo;
	EndIf;
	
	DisplayInformationAboutAddressValidityDate(AddressOnDate);
	
	If Not Modified Then
		Modified = Result.Modified;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function JSONStringToStructure(Value)
	Return ContactsManagerInternal.JSONToContactInformationByFields(Value, Enums.ContactInformationTypes.Address);
EndFunction

&AtClient
Procedure SaveFormState()
	SetFormUsageKey();
	SavedInSettingsDataModified = True;
EndProcedure

&AtClient
Procedure ClearModifiedOnChoice()
	Modified = False;
	CommentCopy   = Comment;
EndProcedure

&AtServerNoContext
Function FlagUpdateSelectionResults(Context, ReturnValueList = False)
	// Update some flags.
	FlagsValue = ContactsManagerInternal.ContactInformationKindStructure(ContactInformationKindDetails(Context).Ref);
	
	Context.ContactInformationKind.OnlyNationalAddress = FlagsValue.OnlyNationalAddress;
	Context.ContactInformationKind.CheckValidity   = FlagsValue.CheckValidity;

	Return SelectionResult(Context, ReturnValueList);
EndFunction

// Parameters:
//  Context - Structure:
//   * ContactInformationKind - See ContactsManagerInternal.ContactInformationKindStructure
//   * LocalityDetailed - Structure
//   * MainCountry - CatalogRef.WorldCountries
//   * Country - CatalogRef.WorldCountries
//  ReturnValueList - Boolean
//
// Returns:
//		See NewSelectionResults
//
&AtServerNoContext
Function SelectionResult(Context, ReturnValueList = False)

	LocalityDetailed = Context.LocalityDetailed;
	Presentation = TrimAll(StrReplace(LocalityDetailed.Value, Chars.LF, " "));
	
	Result = NewSelectionResults();

	Result.ChoiceData.Presentation = Presentation;
	Result.ChoiceData.Comment = LocalityDetailed.Comment;
	Result.ChoiceData.Kind = ContactInformationKindDetails(Context).Ref;
	Result.ChoiceData.Type = Context.ContactInformationKind.Type;
	Result.ChoiceData.Value = 
		ContactsManagerInternal.ToJSONStringStructure(LocalityDetailed);
	Result.ChoiceData.EnteredInFreeFormat = 
		ContactsManagerInternal.AddressEnteredInFreeFormat(LocalityDetailed);
	Result.ChoiceData.AsHyperlink = 
		(Context.ContactInformationKind.Type = Enums.ContactInformationTypes.Address) 
		And (StrCompare(Context.ContactInformationKind.EditingOption, "Dialog") = 0);
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//    * FillingErrors - Array 
//    * ChoiceData - Structure:
//        ** Presentation - String 
//        ** Comment - String 
//        ** Value - String
//        ** EnteredInFreeFormat - Boolean 
//        ** AsHyperlink - Boolean
//        ** Kind - CatalogRef.ContactInformationKinds
//        ** Type - EnumRef.ContactInformationTypes
//
&AtServerNoContext
Function NewSelectionResults()
	
	ChoiceData = New Structure();
	ChoiceData.Insert("Presentation", "");
	ChoiceData.Insert("Comment",   "");
	ChoiceData.Insert("Value",      "");
	ChoiceData.Insert("EnteredInFreeFormat", False);
	ChoiceData.Insert("AsHyperlink",       False);
	ChoiceData.Insert("Kind", Catalogs.ContactInformationKinds.EmptyRef());
	ChoiceData.Insert("Type", Enums.ContactInformationTypes.EmptyRef());
	ChoiceData.Insert("ContactInformation",      ""); //  Obsolete. For backward compatibility purposes.
	
	Result = New Structure;
	Result.Insert("FillingErrors", New Array);
	Result.Insert("ChoiceData",     ChoiceData);
	
	Return  Result;
	
EndFunction


&AtServerNoContext
Function FillContactInformationList(ContactInformationKind, ContactInformationAdditionalAttributesDetails)

	Filter = New Structure("Kind", ContactInformationKind);
	FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	
	ContactInformationList = New Array;
	For Each ContactInformationRow In FoundRows Do
		ContactInformation = New Structure("Presentation, Value, ValidFrom, Comment");
		FillPropertyValues(ContactInformation, ContactInformationRow);
		ContactInformationList.Add(ContactInformation);
	EndDo;
	
	Return ContactInformationList;
EndFunction

&AtServer
Function CommentChoiceOnlyResult(ContactInformationValue, Presentation, Comment)
	
	If ContactsManagerClientServer.IsXMLContactInformation(ContactInformationValue) Then
		// Copy
		NewContactInformation = ContactInformationValue;
		// Modifying the NewContactInfo value.
		ContactsManager.SetContactInformationComment(NewContactInformation, Comment);
		AddressEnteredInFreeFormat = ContactsManagerInternal.AddressEnteredInFreeFormat(ContactInformationValue);
		
	Else
		NewContactInformation = ContactInformationValue;
		AddressEnteredInFreeFormat = False;
	EndIf;
	
	Result = New Structure("ChoiceData, FillingErrors", New Structure, New ValueList);
	Result.ChoiceData.Insert("ContactInformation", NewContactInformation);
	Result.ChoiceData.Insert("Presentation", Presentation);
	Result.ChoiceData.Insert("Comment", Comment);
	Result.ChoiceData.Insert("EnteredInFreeFormat", AddressEnteredInFreeFormat);
	Return Result;
EndFunction

&AtClient
Procedure DisplayFieldsByAddressType()
	
	LocalityDetailed.Country = TrimAll(Country);
	UpdateAddressPresentation();
	
EndProcedure

&AtClient
Procedure DisplayAddressFields(CustomFormatAddress)
	
	Items.GroupAddressRepresentation.Visible = Not CustomFormatAddress;
	Items.AddressByFields.Visible              = Not CustomFormatAddress;
	Items.FreeForm.Visible           = CustomFormatAddress;
	Items.CustomFormatAddress.Check        = CustomFormatAddress;
	
EndProcedure

&AtServer
Procedure SetAttributesValueByContactInformation(AddressData)
	
	// Common attributes.
	AddressPresentation = AddressData.value;
	Comment         = AddressData.comment;
	CommentCopy    = Comment; // Comment copy used to analyze changes.
	
	RefToMainCountry = MainCountry();
	CountryData1 = Undefined;
	If ValueIsFilled(AddressData.country) Then
		CountryData1 = Catalogs.WorldCountries.WorldCountryData(, TrimAll(AddressData.Country));
	EndIf;
	
	If CountryData1 = Undefined Then
		// Country data is found neither in the catalog nor in the ARCC.
		Country    = RefToMainCountry;
		AddressData.country = String(Country);
		MainCountryCode = Common.ObjectAttributeValue(RefToMainCountry, "Code");
		If MainCountryCode <> Undefined Then
			CountryCode = MainCountryCode;
			AddressData.countryCode = CountryCode;
		EndIf;
		
	Else
		Country    = CountryData1.Ref;
		CountryCode = CountryData1.Code;

	EndIf;
	
	Street         = AddressData.street;
	AdditionalInformation         = AddressData.houseNumber;
	City          = AddressData.city;
	State         = AddressData.area;
	PostalCode = AddressData.ZIPCode;
	
EndProcedure

&AtServer
Procedure FillInPredefinedAddressOptions()
	
	If ValueIsFilled(Parameters.IndexOf) Then
		PostalCode = Parameters.IndexOf;
		LocalityDetailed.ZipCode = PostalCode;
	EndIf;
	
	If ValueIsFilled(Parameters.Country) And IsBlankString(LocalityDetailed.Country) Then
		
		If TypeOf(Parameters.Country) = Type("CatalogRef.WorldCountries") Then
			If ValueIsFilled(Parameters.Country) Then
				Country = Parameters.Country;
				LocalityDetailed.Country = Common.ObjectAttributeValue(Parameters.Country, "Description");
			Else
				Country = MainCountry();
				LocalityDetailed.Country = Common.ObjectAttributeValue(Country, "Description");
			EndIf;
		Else
			Country = ContactsManager.WorldCountryByCodeOrDescription(Parameters.Country);
			If Country <> Catalogs.WorldCountries.EmptyRef() Then
				LocalityDetailed.Country = Parameters.Country;
			Else
				Country = MainCountry();
				LocalityDetailed.Country = Common.ObjectAttributeValue(Country, "Description");
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayInformationAboutAddressValidityDate(ValidFrom)
	
	If EnterNewAddress Then
		TextHistoricalAddress = "";
		AddressOnDate = ValidFrom;
		Items.HistoricalAddressGroup.Visible = ValueIsFilled(ValidFrom);
	Else
		
		Filter = New Structure("Kind", ContactInformationKindDetails(ThisObject).Ref);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		If FoundRows.Count() = 0 
			Or (FoundRows.Count() = 1 And IsBlankString(FoundRows[0].Presentation)) Then
				AddressOnDate = Date(1, 1, 1);
				Items.HistoricalAddressGroup.Visible = False;
				Items.ChangeHistory.Visible = False;
		Else
			Result = DefineValidDate(ValidFrom, FoundRows);
			AddressOnDate = Result.ValidFrom;
			AddressValidFrom = Result.ValidFrom;
			
			If Not ValueIsFilled(Result.ValidFrom)
				And IsBlankString(Result.CurrentRow.Presentation) Then
					Items.HistoricalAddressGroup.Visible = False;
			ElsIf ValueIsFilled(Result.ValidTo) Then
				TextHistoricalAddress = " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'có hiệu lực đến %1';
																											|ru = 'действует по %1';
																											|en = 'valid until %1'; fa = 'valid until %1';
																											|it = 'in vigore al %1';
																											|pl = 'aktuylny do %1';
																											|tr = '%1 kadar geçerli'"), Format(Result.ValidTo - 10, "DLF=DD"));
			Else
				TextHistoricalAddress = NStr("vi = 'có hiệu lực đến hết thời gian này.';
											|ru = 'действует по настоящее время.';
											|en = 'valid as of today.'; fa = 'valid as of today.';
											|it = 'valido fino ad oggi.';
											|pl = 'ważne do chwili obecnej.';
											|tr = 'bugün itibariyle geçerli.'");
			EndIf;
			DisplayRecordsCountInHistoryChange();
		EndIf;
	EndIf;
	
	Items.AddressStillValid.Title = TextHistoricalAddress;
	Items.AddressOnDate.EditFormat = ?(ValueIsFilled(AddressOnDate), "", "DF='""" + TheBeginningOfTheAccounting() + """'");
	
EndProcedure

&AtServer
Procedure DisplayRecordsCountInHistoryChange()
	
	Filter = New Structure("Kind", ContactInformationKindDetails(ThisObject).Ref);
	FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	If FoundRows.Count() > 1 Then
		Items.ChangeHistoryHyperlink.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lịch sử thay đổi (%1)';
																											|ru = 'История изменений (%1)';
																											|en = 'Change history (%1)'; fa = 'Change history (%1)';
																											|it = 'Cronologia delle modifiche (%1)';
																											|pl = 'Historia edycji (%1)';
																											|tr = 'Değişiklik geçmişi (%1)'"), FoundRows.Count());
		Items.ChangeHistoryHyperlink.Visible = True;
	ElsIf FoundRows.Count() = 1 And IsBlankString(FoundRows[0].Value) Then
		Items.ChangeHistoryHyperlink.Visible = False;
	Else
		Items.ChangeHistoryHyperlink.Title = NStr("vi = 'Lịch sử thay đổi';
													|ru = 'История изменений';
													|en = 'Change history'; fa = 'سابقه تغییرات';
													|it = 'Cronologia delle modifiche';
													|pl = 'Historia zmian';
													|tr = 'Değişiklik geçmişi'");
		Items.ChangeHistoryHyperlink.Visible = True;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function DefineValidDate(ValidFrom, History)
	
	Result = New Structure("ValidTo, ValidFrom, CurrentRow");
	If History.Count() = 0 Then
		Return Result;
	EndIf;
	
	CurrentRow        = Undefined;
	ValidTo          = Undefined;
	Min              = -1;
	MinComparative = Undefined;
	
	For Each HistoryString In History Do
		Delta = HistoryString.ValidFrom - ValidFrom;
		If Delta <= 0 And (MinComparative = Undefined Or Delta > MinComparative) Then
			CurrentRow        = HistoryString;
			MinComparative = Delta;
		EndIf;

		If Min = -1 Then
			Min       = Delta + 1;
			CurrentRow = HistoryString;
		EndIf;
		If Delta > 0 And ModuleNumbers(Delta) < ModuleNumbers(Min) Then
			ValidTo = HistoryString.ValidFrom;
			Min     = ModuleNumbers(Delta);
		EndIf;
	EndDo;
	
	Result.ValidTo   = ValidTo;
	Result.ValidFrom    = CurrentRow.ValidFrom;
	Result.CurrentRow = CurrentRow;
	
	Return Result;
EndFunction

&AtClientAtServerNoContext
Function ModuleNumbers(Number)
	Return Max(Number, -Number);
EndFunction

&AtClient
Procedure ClearAddressClient()
	
	For Each AddressItem In LocalityDetailed Do
		
		If AddressItem.Key = "Type" Then
			Continue;
		Else
			LocalityDetailed[AddressItem.Key] = "";
		EndIf;
		
	EndDo;
	
	ClearAddressFieldsOnForm();
	
EndProcedure

&AtClient
Procedure ClearAddressFieldsOnForm()
	Street                           = "";
	AdditionalInformation        = "";
	City                           = "";
	State                          = "";
	PostalCode                  = "";
	ForeignAddressPresentation = "";
	AddressPresentation             = "";
EndProcedure

&AtServer
Procedure SetFormUsageKey()
	WindowOptionsKey = String(Country);
EndProcedure

////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Procedure OnCreateAtServerStoreChangeHistory()
	
	If ContactInformationKind.StoreChangeHistory Then
		If ValueIsFilled(Parameters.ContactInformationAdditionalAttributesDetails) Then
			For Each CIRow In Parameters.ContactInformationAdditionalAttributesDetails Do
				NewRow = ContactInformationAdditionalAttributesDetails.Add();
				FillPropertyValues(NewRow, CIRow);
			EndDo;
		Else
			Items.ChangeHistory.Visible           = False;
		EndIf;
		EnterNewAddress = Parameters.EnterNewAddress;
		Items.ChangeHistoryHyperlink.Visible = Not Parameters.FromHistoryForm;
		If EnterNewAddress Then
			ValidFrom = Parameters.ValidFrom;
		Else
			ValidFrom = ?(ValueIsFilled(Parameters.ValidFrom), Parameters.ValidFrom, CurrentSessionDate());
		EndIf;
		DisplayInformationAboutAddressValidityDate(ValidFrom);
	Else
		Items.ChangeHistory.Visible           = False;
		Items.HistoricalAddressGroup.Visible    = False;
	EndIf;

EndProcedure

&AtServer
Function DefineAddressValue(Var_Parameters)
	
	If ValueIsFilled(Var_Parameters.Value) Then
		FieldValues = Var_Parameters.Value;
	Else
		FieldValues = Var_Parameters.FieldValues;
	EndIf;
	
	Return FieldValues;

EndFunction

&AtServerNoContext
Function MainCountry()
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		
		ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
		Return ModuleAddressManagerClientServer.MainCountry();
		
	EndIf;
	
	Return Catalogs.WorldCountries.EmptyRef();

EndFunction

&AtServer
Function PrepareAddressForInput(Data)
	
	LocalityDetailed = ContactsManagerClientServer.NewContactInformationDetails(PredefinedValue("Enum.ContactInformationTypes.Address"));
	FillPropertyValues(LocalityDetailed, Data);
	
	Return LocalityDetailed;
	
EndFunction

// Returns:
//   See ContactsManagerInternal.ContactInformationKindStructure
//
&AtClientAtServerNoContext
Function ContactInformationKindDetails(Form)
	Return Form.ContactInformationKind;
EndFunction

// Fill address presentation.
// 
// Parameters:
//  Address - See ContactsManagerClientServer.NewContactInformationDetails
//  IncludeCountryInPresentation - Boolean
//  AddressType - String, Undefined 
//
&AtClient
Procedure FillAddressPresentation(Address, IncludeCountryInPresentation, AddressType = Undefined)
	
	If AddressType = Undefined Then
		AddressType = Address.AddressType;
	EndIf;
	
	If ContactsManagerClientServer.IsAddressInFreeForm(AddressType)Then
		Address.value     = PresentationOfAddressInFreeForm(Address, IncludeCountryInPresentation);
		Address.admLevels = New Array;
	EndIf;
	
	FilledLevelsList = New Array;
	AddressValueList     = New Array;
	
	LevelsInAddressOrder = FieldsInAddressOrder(IncludeCountryInPresentation);
	
	For Each LevelName In LevelsInAddressOrder Do
		If ValueIsFilled(Address[LevelName]) Then
			AddressValueList.Add(Address[LevelName]);
			FilledLevelsList.Add(LevelName);
		EndIf;
	EndDo;
	
	Address.value     = StrConcat(AddressValueList, ", ");
	Address.admLevels = FilledLevelsList;
	
EndProcedure

&AtClientAtServerNoContext
Function TheBeginningOfTheAccounting()
	
	Return NStr("vi = 'bắt đầu ghi nhận';
				|ru = 'начало учета';
				|en = 'accounting start date'; fa = 'accounting start date';
				|it = 'inizio contabilità';
				|pl = 'początek rachunkowości';
				|tr = 'kayıt başlangıcı'");
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_AddressOnDate" Then
		AddressOnDateOnChange(Items.AddressOnDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion

// @strict-types

#Region Public

// Opens the address entry form with the address field values filled in from the parameter.
//
// Parameters:
//	Item - FormField - the Form element for entering the address
//	Address - String - text Presentation of the address
//	AddressValue - String - JSON Presentation of the address
//	Notification - CallbackDescription - method of processing the result of the Form
//
Procedure OpenAddressSelectionForm(Item, Address, AddressValue, Notification) Export
	
	KindParameters = GoodsDeliveryServerCall.AddressParameters();
	KindParameters.Description = NStr("ru = 'Адрес';
										|vi = 'Address';
										|en = 'Address'; fa = 'آدرس';
										|it = 'Address';
										|pl = 'Address';
										|tr = 'Adres'");
	
	OpeningParameters = ContactsManagerClient.ContactInformationFormParameters(
		KindParameters,
		AddressValue,
		Address,
		,
		PredefinedValue("Enum.ContactInformationTypes.Address"));
	
	ContactsManagerClient.OpenContactInformationForm(OpeningParameters,, Notification);
		
EndProcedure

// Opens the Delivery settings Form for ordering
// 
// Parameters:
//  FormParameters - Structure
//  CompletionDetails - CallbackDescription
//
Procedure OpenDeliverySettingsForm(FormParameters, CompletionDetails) Export
	
	OpenForm("DataProcessor.EditingDeliveryParameters.Form.DeliveryParameters", FormParameters,,,,, CompletionDetails);
	
EndProcedure

// Checks the Balance to be shipped and, if available, informs the user about the impossibility of the transition
// 
// Returns:
//  Boolean - 
//
Async Function CheckPossibilityOfSwitchingToDelivery25Async() Export
	
	BeginVerification = Await VerificationOfPossibilityOfSwitchingToDeliveryIsAvailable25();
	If BeginVerification Then
		
		CheckResult = GoodsDeliveryServerCall.CheckPossibilityOfSwitchingToDelivery25();
		TransitionIsAvailable = CheckResult.TransitionIsAvailable;
		
		If Not TransitionIsAvailable Then
			
			WarningText = GoodsDeliveryClientServer.TextOfVerificationOfPossibilityOfSwitchingToDelivery25(
				CheckResult);
			
			Await DoMessageBoxAsync(WarningText);
			
		EndIf;
		
	Else
		
		TransitionIsAvailable = False;
		
	EndIf;
	
	Return TransitionIsAvailable;
	
EndFunction

#Region Delivery20

// Opens the address entry form with the address field values filled in from the parameter.
//
// Parameters:
//	Item - FormField - form element for entering an address;
//	Object - FormDataCollection - object that the event is being executed for;
//	NamesOfDetailsOfDeliveryAddresses - See GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses
//	StandardProcessing - Boolean - True, indicates that the standard processing of the start selection event has been performed.
//
Procedure OpenAddressSelectionFormAndProcessResult(Item, Object, NamesOfDetailsOfDeliveryAddresses, StandardProcessing = False) Export
	
	StandardProcessing = False;
	
	AddressPresentation = Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress]; // String
	FieldValueAddress = Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]; // String
	AddressValue = Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue];
	
	If Not DeliveryAddressFieldValuesAreValid(FieldValueAddress) Then
		
		FieldValueAddress = "";
		AddressValue = "";
		GeneralPurposeTMServerCall.FillInValuesOfCIFieldsOnPresentation(AddressPresentation, FieldValueAddress);
		
	EndIf;
	
	WhenChangingAddressPresentation(Item, AddressPresentation, FieldValueAddress, False);
	
	// Let's open the KI editing dialog
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ContactInformationKind", PredefinedValue("Catalog.ContactInformationKinds.PartnerAddress"));
	OpeningParameters.Insert("FieldValues",           GoodsDeliveryClientServer.ConvertStringToFieldsList(FieldValueAddress));
	OpeningParameters.Insert("Value",                AddressValue);
	OpeningParameters.Insert("Presentation",           AddressPresentation);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",						Object);
	AdditionalParameters.Insert("NameOfDetailsOfDeliveryAddress", 	NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress);
	AdditionalParameters.Insert("Item", 					Item);
	
	Notification = New CallbackDescription("OpenAddressSelectionFormAndProcessResultCompletion", 
		GoodsDeliveryClient, AdditionalParameters);
	
	ContactsManagerClient.OpenContactInformationForm(OpeningParameters,,Notification);
		
EndProcedure

// Updates the CI from the input field editing text.
//
// Parameters:
//		Item - FormField - form element for entering an address;
//		AddressPresentation - String - representation of the address;
//		FieldValueAddress - String - service information, address field values.
//		ClearEmptyPresentation - Boolean - the truth, clear.
//
Procedure WhenChangingAddressPresentation(Item, AddressPresentation, FieldValueAddress, ClearEmptyPresentation = True) Export
	
	If Item.Type = FormFieldType.InputField Then
		AddressPresentation = Item.EditText; // String
		
		If ClearEmptyPresentation
			And AddressPresentation = "" Then
			ClearAddressPresentation(AddressPresentation, FieldValueAddress);
		EndIf;
		
		GeneralPurposeTMServerCall.FillInValuesOfCIFieldsOnPresentation(AddressPresentation, FieldValueAddress);
	EndIf;
	
EndProcedure

// Clears the CI fields when clearing the input field editing text.
//
// Parameters:
//		AddressPresentation - String - representation of the address.
//		FieldValueAddress - String - service information, address field values.
//		AddressValue - String - the address in the internal JSON format or in XML corresponding to the Address XDTO package.
//
Procedure ClearAddressPresentation(AddressPresentation, FieldValueAddress, AddressValue = "") Export
	
	AddressPresentation = "";
	FieldValueAddress = "";
	AddressValue = "";
	
EndProcedure

// Fills in the delivery details from the structure according to the selected address
//
// Parameters:
//  FormItems - FormAllItems - elements of the form in which the address is selected (to get the selection lists)
//  DocObject - DocumentObject - the object where the address is selected, the details of this object are filled in with the delivery details
//  FormItemName - String - the name of the form element in which the address is selected
//  ValueSelected - Structure - delivery details corresponding to the selected address
//
Procedure DeliveryAddressChoiceProcessing(FormItems, DocObject, FormItemName, ValueSelected) Export
	
	AdditionalInfoChangedByUser = GoodsDeliveryClientServer.AdditionalInfoChangedByUser(FormItems, DocObject);
	If FormItemName = "RecipientDeliveryAddress" Then
		If AdditionalInfoChangedByUser
			And ValueSelected.Property("AdditionalDeliveryInformation") Then
			FillPropertyValues(DocObject, ValueSelected, , "AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected);
		EndIf;
	ElsIf FormItemName = "DeliveryAddress" Then
		If AdditionalInfoChangedByUser
			And ValueSelected.Property("AdditionalDeliveryInformation") Then
			FillPropertyValues(DocObject, ValueSelected, , "AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected);
		EndIf;
	ElsIf FormItemName = "DeliveryAddressOfCarrier" Then
		If AdditionalInfoChangedByUser 
			And ValueSelected.Property("AdditionalDeliveryInformation") Then
			FillPropertyValues(DocObject, ValueSelected,
				,"DeliveryAddress, DeliveryAddressFieldValues, AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected,
				,"DeliveryAddress, DeliveryAddressFieldValues");
		EndIf;
		DocObject.DeliveryAddressOfCarrier = ValueSelected.DeliveryAddress; // String
		DocObject.DeliveryAddressOfCarrierFieldValues = ValueSelected.DeliveryAddressFieldValues; // String
		
	ElsIf FormItemName = "RecipientDeliveryAddress1" Then
		If AdditionalInfoChangedByUser
			And ValueSelected.Property("AdditionalDeliveryInformation") Then
			FillPropertyValues(DocObject, ValueSelected, , "AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected);
		EndIf;
	ElsIf FormItemName = "RecipientDeliveryAddress2" Then
		If ValueSelected.Property("AdditionalDeliveryInformation")
			And (AdditionalInfoChangedByUser
				Or ValueIsFilled(ValueSelected.AdditionalDeliveryInformation)) Then
			FillPropertyValues(DocObject, ValueSelected, , "AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected);
		EndIf;
	ElsIf FormItemName = "DeliveryAddressSelfPickup" Then
		If AdditionalInfoChangedByUser
			And ValueSelected.Property("AdditionalDeliveryInformation") Then
			FillPropertyValues(DocObject, ValueSelected, , "AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected);
		EndIf;
	ElsIf FormItemName = "SupplierSAddress" Then
		If AdditionalInfoChangedByUser Then
			FillPropertyValues(DocObject, ValueSelected, , "AdditionalDeliveryInformation");
		Else
			FillPropertyValues(DocObject, ValueSelected);
		EndIf;
		
	EndIf;
	
EndProcedure

//Fills in the list of carriers on the form.
//
// Parameters:
//  CarrierSelectionList - ValueList - list of selected carriers.
//  BackgroundTaskData - See TimeConsumingOperations.ExecuteInBackground
//
Procedure UpdateListOfCarriers(CarrierSelectionList, BackgroundTaskData) Export

	ArrayOfCarriers = GoodsDeliveryServerCall.GetDeleteFromTempStorage(BackgroundTaskData.ResultAddress);
	
	CarrierSelectionList.LoadValues(ArrayOfCarriers);
	
	BackgroundTaskData = Undefined;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Checks incomplete transportation tasks and asks the user if the transition will continue
// 
// Returns:
//  Boolean -
//
Async Function VerificationOfPossibilityOfSwitchingToDeliveryIsAvailable25()
	
	InformationAboutTransportationTasks = GoodsDeliveryServerCall.DataForTransportationTasksWithoutDeliveryMark();
	
	If InformationAboutTransportationTasks.DocumentsCount > 0 Then
		
		AddInformationAboutIncompleteTransportationTasksToLog(InformationAboutTransportationTasks);
		
		QueryText = NStr("ru = 'До перехода на доставку 2.5 рекомендуется установить флаг ""Все товары по пункту маршрута доставлены"" в пунктах маршрута заданий на перевозку в статусе ""Закрыто"".
			|Это позволит уменьшить нагрузку на систему при проверке завершения отгрузки по распоряжениям с запланированной доставкой.
			|Продолжить?';
			|vi = 'Before migrating to delivery 2.5, it is recommended that you set the ""All goods delivered to route point"" checkbox at the route points of itineraries with the ""Closed"" status.
			|This will reduce the load on the system when checking the completion of shipments on references with scheduled delivery.
			|Continue?';
			|en = 'Before migrating to delivery 2.5, it is recommended that you set the ""All goods delivered to route point"" checkbox at the route points of itineraries with the ""Closed"" status.
			|This will reduce the load on the system when checking the completion of shipments on references with scheduled delivery.
			|Continue?'; fa = 'Before migrating to delivery 2.5, it is recommended that you set the ""All goods delivered to route point"" checkbox at the route points of itineraries with the ""Closed"" status.
			|This will reduce the load on the system when checking the completion of shipments on references with scheduled delivery.
			|Continue?';
			|it = 'Before migrating to delivery 2.5, it is recommended that you set the ""All goods delivered to route point"" checkbox at the route points of itineraries with the ""Closed"" status.
			|This will reduce the load on the system when checking the completion of shipments on references with scheduled delivery.
			|Continue?';
			|pl = 'Before migrating to delivery 2.5, it is recommended that you set the ""All goods delivered to route point"" checkbox at the route points of itineraries with the ""Closed"" status.
			|This will reduce the load on the system when checking the completion of shipments on references with scheduled delivery.
			|Continue?';
			|tr = 'Teslimat 2.5''e geçişten önce, ""Kapalı"" durumundaki taşıma görevlerinin rota noktalarındaki ""Rota noktasına ait tüm mallar teslim edildi"" bayrağının işaretlenmesi önerilir. 
			| Bu, planlı teslimatlı talimatların sevkiyatının tamamlandığını kontrol ederken sistemdeki yükü azaltır. 
			| Devam edilsin mi?'");
		
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No); // DialogReturnCode
		
		GoToVerification = (Response = DialogReturnCode.Yes);
		
	Else
		
		GoToVerification = True;
		
	EndIf;
	
	Return GoToVerification;
	
EndFunction

Procedure AddInformationAboutIncompleteTransportationTasksToLog(InformationAboutTransportationTasks)
	
	EventName = NStr("ru = 'Переход на управление доставкой 2.5';
					|vi = 'Migration to delivery management 2.5';
					|en = 'Migration to delivery management 2.5'; fa = 'مهاجرت به مدیریت تحویل 2.5';
					|it = 'Migration to delivery management 2.5';
					|pl = 'Migration to delivery management 2.5';
					|tr = 'Teslimat 2.5 yönetimine geçiş'", CommonClient.DefaultLanguageCode());
	
	MessageTemplate = NStr("ru = 'Перед началом перехода на управление доставкой 2.5 найдено %1 закрытых заданий на перевозку, в которых не отмечена доставка по всем пунктам маршрута (флаг ""Все товары по пункту маршрута доставлены""):
								 |%2';
								 |vi = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
								 |%2';
								 |en = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
								 |%2'; fa = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
								 |%2';
								 |it = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
								 |%2';
								 |pl = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
								 |%2';
								 |tr = 'Teslimat 2.5 yönetimine geçiş başlatılmadan önce, tüm rota noktalarındaki teslimat işaretlenmemiş (""Rota noktasına ait tüm mallar teslim edildi"" bayrağı) kapalı taşıma görevi %1 adet bulundu:
								 | %2'");
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		MessageTemplate,
		Format(InformationAboutTransportationTasks.DocumentsCount, "NG=0"),
		InformationAboutTransportationTasks.DocumentsInfo);
	
	EventLogClient.AddMessageForEventLog(EventName, "Warning", MessageText);
	
EndProcedure

#Region Delivery20

Procedure OpenAddressSelectionFormAndProcessResultCompletion(Result, AdditionalParameters) Export 
	
	Item = AdditionalParameters.Item;
	Object = AdditionalParameters.Object;
	NameOfDetailsOfDeliveryAddress = AdditionalParameters.NameOfDetailsOfDeliveryAddress;
		
	If TypeOf(Result) = Type("Structure") Then // CI is introduced
		
		// Transfer the data to the form
		Object[NameOfDetailsOfDeliveryAddress + "FieldValues"] = Result.ContactInformation;
		Object[NameOfDetailsOfDeliveryAddress + "Value"] = Result.Value;
		Object[NameOfDetailsOfDeliveryAddress] = Result.Presentation;
		
		// Let's set the sign of modification
		Parent = Item.Parent; // ClientApplicationForm  
		While TypeOf(Parent) <> Type("ClientApplicationForm") Do
			Parent = Parent.Parent;
		EndDo;
		
		If Parent.FormName <> "DataProcessor.WorkplaceOfDeliveryOfficer.Form.Form" Then
			Parent.Modified = True;
		EndIf;
		Parent.RefreshDataRepresentation();
		
	EndIf;

EndProcedure

// Parameters:
//  FieldValueAddress - String - Address of the field values
// 
// Returns:
//  Boolean - Delivery Address Field Values Are Valid
//
Function DeliveryAddressFieldValuesAreValid(FieldValueAddress)
	
	FieldValuesAreValid = IsBlankString(FieldValueAddress)
		Or (StrStartsWith(FieldValueAddress, "<")
		And StrEndsWith(FieldValueAddress, ">"))
		Or (StrStartsWith(FieldValueAddress, "{")
		And StrEndsWith(FieldValueAddress, "}"));
		
	Return FieldValuesAreValid;
	
EndFunction

#EndRegion

#EndRegion

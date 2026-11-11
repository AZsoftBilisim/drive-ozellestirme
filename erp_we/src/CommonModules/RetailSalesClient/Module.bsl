#Region Public

// Opens a cash shift
//
// Parameters:
//  CashRegisterParameters - Structure, FixedStructure - yandex.checkout Cash Register Parameters:
//  	* DeviceID - CatalogRef.Peripherals
//  	* UseWithoutConnectingPeripherals - Boolean
//  	* CashRegister - CatalogRef.CashRegisters
//  CallbackDescriptionCompletion - CallbackDescription - Description of the notification when the operation is completed.
//
Procedure OpenRegisterShift(CashRegisterParameters, CallbackDescriptionCompletion = Undefined) Export
	
	ParametersForNotifyingEndOfOperation = New Structure;

	CashRegister = Undefined;
	CashRegisterForTravelingTrade = False;
	CashRegisterWithoutHardwareConnection = False;
	
	If (TypeOf(CashRegisterParameters) = Type("FixedStructure")
		Or TypeOf(CashRegisterParameters) = Type("Structure"))
		And CashRegisterParameters.UseWithoutConnectingPeripherals Then
		
		CashRegisterWithoutHardwareConnection = True;
		CashRegister = CashRegisterParameters.CashRegister;
		CashRegisterForTravelingTrade = CashRegisterParameters.ItinerantTrade;
		
	Else
		
		CashRegisterWithoutHardwareConnection = False;
		If TypeOf(CashRegisterParameters) = Type("FixedStructure")
			Or TypeOf(CashRegisterParameters) = Type("Structure") Then
			FiscalDevice = CashRegisterParameters.DeviceID;
		Else
			FiscalDevice = CashRegisterParameters;
		EndIf;
		
		ParametersForNotifyingEndOfOperation.Insert("FiscalDevice", FiscalDevice);
		ParametersForNotifyingEndOfOperation.Insert("DetailsOfTheCashier", RetailSalesServerCall.DetailsOfTheCashier());
		ParametersForNotifyingEndOfOperation.Insert("DetailsOfAddressOfPlaceOfSettlement", RetailSalesServerCall.DetailsOfAddressOfPlaceOfSettlement(FiscalDevice));

		CashRegister = RetailSalesServerCall.CashDeskCashRegisterForPlugInEquipmentForCWP(FiscalDevice);
		If ValueIsFilled(CashRegister) Then
			ParametersOfCashRegisterOfFiscalDevice = RetailSalesServerCall.CashRegisterParameters(CashRegister);
			CashRegisterForTravelingTrade = ParametersOfCashRegisterOfFiscalDevice.ItinerantTrade;
		EndIf;
		
	EndIf;
	
	ParametersForNotifyingEndOfOperation.Insert("CashRegisterWithoutHardwareConnection", CashRegisterWithoutHardwareConnection);
	ParametersForNotifyingEndOfOperation.Insert("CashRegister", CashRegister);	
	ParametersForNotifyingEndOfOperation.Insert("CashRegisterParameters", CashRegisterParameters);
	ParametersForNotifyingEndOfOperation.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	NotificationOfEndOfOperation = New CallbackDescription("OpenRegisterShiftCompletion", ThisObject, ParametersForNotifyingEndOfOperation);
	If CashRegisterForTravelingTrade Then
		FormOpenParameters = New Structure;
		OpenForm("Document.CashRegisterShift.Form.RequestFormOfARAPAccountingLocation",
					FormOpenParameters,
					,
					,
					,
					,
					NotificationOfEndOfOperation,
					FormWindowOpeningMode.LockWholeInterface);
	Else
		RunCallback(NotificationOfEndOfOperation, Undefined);
	EndIf;
	
EndProcedure

// Open the cash shift End.
// 
// Parameters:
//  Result - Structure - the result of opening a cash shift
//  Parameters - Structure - Cash Shift Parameters
Procedure OpenRegisterShiftCompletion(Result, Parameters) Export
	
	CashRegister = Parameters.CashRegister;
	CashRegisterWithoutHardwareConnection = Parameters.CashRegisterWithoutHardwareConnection;
	
	CallbackDescriptionCompletion = Parameters.CallbackDescriptionCompletion;
	
	AdditionalParameters = New Structure;
	
	// Address and place of settlement where traveling trade is carried out
	SettlementAddress = Undefined;
	PlaceOfSettlement = Undefined;
	If TypeOf(Result) = Type("Structure") 
		And Result.Result = DialogReturnCode.OK Then
		If ValueIsFilled(Result.SettlementAddress) Then
			SettlementAddress = Result.SettlementAddress;
			AdditionalParameters.Insert("SettlementAddress", SettlementAddress);
		EndIf;
		If ValueIsFilled(Result.PlaceOfSettlement) Then
			PlaceOfSettlement = Result.PlaceOfSettlement;
			AdditionalParameters.Insert("PlaceOfSettlement", PlaceOfSettlement);
		EndIf;
	EndIf;
	
	If CashRegisterWithoutHardwareConnection Then
		
		ErrorDescription = "";
		Result = RetailSalesServerCall.OpenRegisterShift(CashRegister, AdditionalParameters, ErrorDescription);
		If Not Result Then
			
			MessageText = StrTemplate(
				NStr("vi = 'Khi mở phiên làm việc, đã xảy ra lỗi.
				           |Chưa đóng phiên làm việc.
				           |Mô tả bổ sung:
				           |%1';
				           |ru = 'При открытии смены произошла ошибка.
				           |Смена не открыта.
				           |Дополнительное описание:
				           |%1';
				           |en = 'An error occurred while opening the shift.
				           |The shift is not opened.
				           |Additional details:
				           |%1'; fa = 'An error occurred while opening the shift.
				           |The shift is not opened.
				           |Additional details:
				           |%1';
				           |it = 'Si è verificato un errore durante l''apertura del turno.
				           |Il turno non è aperto.
				           |Ulteriore descrizione:
				           |%1';
				           |pl = 'Podczas otwierania zmiany wystąpił błąd.
				           |Zmiana nie jest otwarta.
				           |Dodatkowy opis:
				           |%1';
				           |tr = 'Vardiya açılırken hata oluştu.
				           |Vardiya açık değil.
				           |Ek ayrıntılar:
				           |%1'"),
				ErrorDescription);
			CommonClient.MessageToUser(MessageText);
			
		EndIf;
		
		If CallbackDescriptionCompletion <> Undefined Then
			RunCallback(CallbackDescriptionCompletion, Result);
		EndIf;
		
	Else
		
		Context = New Structure;
		Context.Insert("FiscalDevice",         Parameters.FiscalDevice);
		Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
		
		OperationParametersList = PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift();
		DetailsOfTheCashier = Parameters.DetailsOfTheCashier; // See RetailSalesServerCall.DetailsOfTheCashier
		OperationParametersList.Cashier = DetailsOfTheCashier.Description;
		OperationParametersList.CashierTIN = DetailsOfTheCashier.TIN;

		OperationParametersList.SettlementAddress = ?(ValueIsFilled(SettlementAddress), SettlementAddress, Parameters.DetailsOfAddressOfPlaceOfSettlement.SettlementAddress);
		OperationParametersList.PlaceOfSettlement = ?(ValueIsFilled(PlaceOfSettlement), PlaceOfSettlement, Parameters.DetailsOfAddressOfPlaceOfSettlement.PlaceOfSettlement);
		
		AdditionalParameters.Insert("CashRegister", CashRegister);
		
		PeripheralsReceiptPrintersClient.StartOpeningShiftOnFiscalDevice(
			New CallbackDescription("AfterExecutingOpenShiftCommand", ThisObject, Context),
			New UUID,
			Parameters.FiscalDevice,
			OperationParametersList,
			AdditionalParameters);
		
	EndIf;
		
EndProcedure

// Closes the cash register shift
//
// Parameters:
//  CashRegisterParameters - Structure, FixedStructure - yandex.checkout Cash Register Parameters:
//  	* DeviceID - CatalogRef.Peripherals
//  	* UseWithoutConnectingPeripherals - Boolean
//  	* CashRegister - CatalogRef.CashRegisters
//  CallbackDescriptionCompletion - CallbackDescription - Description of the notification when the operation is completed.
//
Procedure CloseRegisterShift(CashRegisterParameters, CallbackDescriptionCompletion = Undefined) Export
	
	If (TypeOf(CashRegisterParameters) = Type("FixedStructure")
		Or TypeOf(CashRegisterParameters) = Type("Structure"))
		And CashRegisterParameters.UseWithoutConnectingPeripherals Then
		
		GenerateReportOnRetailSales(CashRegisterParameters.CashRegister);
		
		RunCallback(CallbackDescriptionCompletion, True);
		
	Else
		
		If TypeOf(CashRegisterParameters) = Type("FixedStructure")
			Or TypeOf(CashRegisterParameters) = Type("Structure") Then
			FiscalDevice = CashRegisterParameters.DeviceID;
		Else
			FiscalDevice   = CashRegisterParameters;
		EndIf;
		
		Context = New Structure;
		Context.Insert("FiscalDevice",         FiscalDevice);
		Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
		
		OperationParametersList = PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift();
		
		DetailsOfTheCashier = RetailSalesServerCall.DetailsOfTheCashier();
		OperationParametersList.Cashier = DetailsOfTheCashier.Description;
		OperationParametersList.CashierTIN = DetailsOfTheCashier.TIN;

 		DetailsOfAddressOfPlaceOfSettlement = RetailSalesServerCall.DetailsOfAddressOfPlaceOfSettlement(FiscalDevice);
		OperationParametersList.SettlementAddress = DetailsOfAddressOfPlaceOfSettlement.SettlementAddress;
		OperationParametersList.PlaceOfSettlement = DetailsOfAddressOfPlaceOfSettlement.PlaceOfSettlement;
		
		ShiftStatusProcessingParameters = RetailSalesServerCall.GetShiftStateProcessingParameters(FiscalDevice);
		If ShiftStatusProcessingParameters.StructureRegisterShiftState.ItinerantTrade Then
			If ValueIsFilled(ShiftStatusProcessingParameters.StructureRegisterShiftState.SettlementAddress) Then
				OperationParametersList.SettlementAddress = ShiftStatusProcessingParameters.StructureRegisterShiftState.SettlementAddress;	
			EndIf;
			If ValueIsFilled(ShiftStatusProcessingParameters.StructureRegisterShiftState.PlaceOfSettlement) Then
				OperationParametersList.PlaceOfSettlement = ShiftStatusProcessingParameters.StructureRegisterShiftState.PlaceOfSettlement;	
			EndIf;
		EndIf;
				
		PeripheralsReceiptPrintersClient.StartClosingShiftOnFiscalDevice(
			New CallbackDescription("AfterExecutingShiftCloseCommand", ThisObject, Context),
			New UUID,
			FiscalDevice,
			OperationParametersList);
		
	EndIf;
	
EndProcedure

// Generate a report without blanking.
// 
// Parameters:
//  CashRegisterParameters - See CloseRegisterShift.CashRegisterParameters
//  CallbackDescriptionCompletion - CallbackDescription - Description of the notification when the operation is completed.
//
Procedure GenerateReportWithoutCancellation(CashRegisterParameters, CallbackDescriptionCompletion = Undefined) Export
	                    
	Context = New Structure;
	Context.Insert("FiscalDevice",         CashRegisterParameters.DeviceID);
	Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	OperationParametersList = PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift(); 
	DetailsOfTheCashier = RetailSalesServerCall.DetailsOfTheCashier();
	OperationParametersList.Cashier = DetailsOfTheCashier.Description;
	OperationParametersList.CashierTIN = DetailsOfTheCashier.TIN;
	
	PeripheralsReceiptPrintersClient.StartGeneratingReportWithoutBlanking(
			New CallbackDescription("AfterExecutingCommandReportWithoutCancellation", ThisObject, Context),
			New UUID,
			CashRegisterParameters.DeviceID,
			OperationParametersList);  
			
EndProcedure

// Opens the form for entering the amount before the operation of depositing funds
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  CashRegisterParameters - Structure -
//  CallbackDescriptionCompletion - CallbackDescription - 
//
Procedure DepositCash(Form, CashRegisterParameters, CallbackDescriptionCompletion = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Form",                        Form);
	Context.Insert("CashRegisterParameters",            CashRegisterParameters);
	Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CashRegister", CashRegisterParameters.CashRegister);
	
	OpenForm(
		"Document.DepositCashIntoCashRegister.Form.EnterAmount",
		OpeningParameters,,,,,
		New CallbackDescription("DepositingMoneyCompletion", ThisObject, Context),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens the form for entering the amount before the withdrawal operation
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  CashRegisterParameters - Structure -
//  CallbackDescriptionCompletion - CallbackDescription - 
//
Procedure CashWithdrawal(Form, CashRegisterParameters, CallbackDescriptionCompletion = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Form",                        Form);
	Context.Insert("CashRegisterParameters",            CashRegisterParameters);
	Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	OpenForm(
		"Document.CashWithdrawalFromCashRegister.Form.EnterAmount",
		New Structure("Currency", CashRegisterParameters.Currency),,,,,
		New CallbackDescription("WithdrawalOfMoneyCompletion", ThisObject, Context),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Updates the information displayed on the buyer's display
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  DeviceID - String -
//  Text - String - 
//
Procedure DisplayTextOnBuyerSDisplay(Form, DeviceID, Text) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",                             Form);
	AdditionalParameters.Insert("DeviceID",           DeviceID);
	AdditionalParameters.Insert("TextToDisplayBuyer", Text);
	
	PeripheralsCustomerDisplaysServerClient.StartCleaningBuyerSDisplay_(
		New CallbackDescription("AfterCompletingCleaningOfBuyerSDisplay", ThisObject, AdditionalParameters),
		Form.UUID,
		DeviceID);
	
EndProcedure

// Updates the displayed information on all customer displays
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  Displays - ValueList of Structure - A list of values from data structures describing displays.
//  Text - String - Output text
//
Procedure DisplayTextOnBuyerSDisplays(Form, Displays, Text) Export
	
	For Each ListItem In Displays Do
		
		Display = ListItem.Value; // Structure
		
		If Not EquipmentManagerTMClient.EquipmentAttached(Display.Ref) Then
			Continue;
		EndIf;
		
		RetailSalesClient.DisplayTextOnBuyerSDisplay(
			Form,
			Display.Ref,
			Text);
		
	EndDo;
	
EndProcedure

// Prepares data for display on the buyer's display.
//
// Parameters:
//  Title - String - Title of the value displayed on the buyer's display.
//  Value - Number, String - Output value (Amount).
//
// Returns:
//  String - Prepared string.
//
Function PrepareLineForDisplay(Title = "", Value = "") Export
	
	Result = "";
	
	TextLength     = 20;
	Spaces20       = "                    ";
	FormatString = "NFD=2; NGS=' '; NZ=0.00; NG=0";
	
	ValueTotal = Format(Value, FormatString);
	
	ValueLength = StrLen(ValueTotal);
	HeaderLength = StrLen(Title);
	If ValueLength + HeaderLength > TextLength Then
		Result = Left(ValueTotal, TextLength);
	ElsIf ValueLength + HeaderLength = TextLength Then
		Result = Title + ValueTotal;
	Else
		Result = Title + Left(Spaces20, TextLength - HeaderLength - ValueLength) + ValueTotal;
	EndIf;
	
	Return Result;
	
EndFunction

// Launches the mechanism for checking the marking codes by means of KKT
// 
// Parameters:
//  ReceiptPositions - Array - Receipt positions
//  OwnerForm - ClientApplicationForm - Owner form
//  IgnoreButtonTitle - String, Undefined - Ignore button title
//  CallbackOnCompletion - CallbackDescription - Notification of completion
//  ViewForm - ClientApplicationForm, Undefined - View Form
//
Procedure CheckMarkingCodeByMeansOfKKT(ReceiptPositions, OwnerForm, IgnoreButtonTitle = Undefined, CallbackOnCompletion, ViewForm = Undefined) Export
	
	RetailSalesClientLocalization.CheckMarkingCodeByMeansOfKKT(ReceiptPositions, OwnerForm, IgnoreButtonTitle, CallbackOnCompletion, ViewForm);
	
EndProcedure

// Determines whether verification of marking codes by means of KKT is required.
// 
// Parameters:
//  ParametersOfReceiptFiscalizationOperation - Structure - Parameters of the receipt fiscalization operation
// 
// Returns:
//  Boolean - True - verification of marking codes by means of KKT is required
//
Function VerificationOfMarkingCodesByMeansOfKKTIsRequired(ParametersOfReceiptFiscalizationOperation) Export
	
	Return RetailSalesClientLocalization.VerificationOfMarkingCodesByMeansOfKKTIsRequired(ParametersOfReceiptFiscalizationOperation);
	
EndFunction

#Region ShiftStateManagement

// Controls the parameters of the current cash shift, opens and closes the cash shift if necessary.
//
// Parameters:
//  Form - Form - The form of the document that controls the cash shift
//  CallbackDescriptionCompletion - CallbackDescription - Description of the notification when the operation is completed.
//
Procedure ProcessShiftState(Form, CallbackDescriptionCompletion) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "CREParameters") Then
		CashRegisterParameters = Form.CREParameters.DeviceID;
		Form.StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Form.CREParameters.DeviceID);
	Else
		CashRegisterParameters = Form.CashRegisterParameters;
		If TMCommonUseClientServer.HasObjectAttribute(Form, "Object")
			And TMCommonUseClientServer.HasObjectAttribute(Form.Object, "CashRegister") Then
			CashRegister = Form.Object.CashRegister;
		Else
			CashRegister = Form.CashRegister;
		EndIf;
		Form.StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(CashRegister);
	EndIf;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "Object")
		And TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Cashier") Then
		FillPropertyValues(Form.Object, Form.StructureRegisterShiftState,,"Cashier");
	ElsIf TMCommonUseClientServer.HasObjectAttribute(Form, "Object") Then
		FillPropertyValues(Form.Object, Form.StructureRegisterShiftState);
	EndIf;
	
	If Not Form.StructureRegisterShiftState.ShiftIsOpened
		And Form.AccessRights.OpenShift Then
		
		Buttons = New ValueList;
		Buttons.Add("OpenRegisterShift", NStr("vi = 'Mở phiên thu ngân';
												|ru = 'Открыть смену';
												|en = 'Open shift'; fa = 'باز کردن شیفت';
												|it = 'Apri il turno';
												|pl = 'Otwórz zmianę';
												|tr = 'Vardiyayı aç'"));
		Buttons.Add("Cancel",               NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NotificationProcessing", CallbackDescriptionCompletion);
		AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
		AdditionalParameters.Insert("Form", Form);
		
		ShowQueryBox(
			New CallbackDescription("StateManagementAndCommandProcessing", RetailSalesClient, AdditionalParameters),
			NStr("vi = 'Trước khi thực hiện thao tác, bạn phải mở ca làm việc mới.';
				|ru = 'Перед выполнением операции требуется открыть новую кассовую смену.';
				|en = 'Open a new POS shift before executing the transaction.'; fa = 'Open a new POS shift before executing the transaction.';
				|it = 'Prima di eseguire l''operazione, è necessario aprire un nuovo turno di cassa.';
				|pl = 'Przed wykonaniem operacji należy otworzyć nowe przesunięcie kasy.';
				|tr = 'İşlemin gerçekleştirilebilmesi için yeni bir nakit vardiyası açılmalıdır.'"), Buttons);
		Return;
		
	ElsIf Not Form.StructureRegisterShiftState.ShiftIsOpened
		And Not Form.AccessRights.OpenShift Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Phiên thu ngân chưa được mở.';
				|ru = 'Кассовая смена не открыта.';
				|en = 'POS shift is not opened.'; fa = 'POS shift is not opened.';
				|it = 'Turno di cassa non aperto.';
				|pl = 'Zmiana kasy nie otwarta.';
				|tr = 'Kasa vardiyası açılmadı.'"));
		
		RunCallback(CallbackDescriptionCompletion, False);
		Return;
		
	EndIf;
	
	If Form.StructureRegisterShiftState.Error24Hours
		And Form.AccessRights.OpenShift
		And Form.AccessRights.CloseShift Then
		
		Buttons = New ValueList;
		Buttons.Add("CloseAndOpenCashShift", NStr("vi = 'Mở phiên thu ngân';
													|ru = 'Открыть смену';
													|en = 'Open shift'; fa = 'باز کردن شیفت';
													|it = 'Apri il turno';
													|pl = 'Otwórz zmianę';
													|tr = 'Vardiyayı aç'"));
		Buttons.Add("Cancel",                       NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NotificationProcessing", CallbackDescriptionCompletion);
		AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
		AdditionalParameters.Insert("Form", Form);
		
		ShowQueryBox(
			New CallbackDescription("StateManagementAndCommandProcessing", RetailSalesClient, AdditionalParameters),
			NStr("vi = 'Đã hơn 24 giờ kể từ khi mở ca. Trước khi thực hiện thao tác, bạn phải mở ca làm việc mới.';
				|ru = 'С момента открытия смены прошло более 24 часов. Перед выполнением операции требуется открыть новую кассовую смену.';
				|en = 'More than 24 hours have passed since the shift was opened. It is required to open a new POS shift before executing the operation.'; fa = 'More than 24 hours have passed since the shift was opened. It is required to open a new POS shift before executing the operation.';
				|it = 'Dal momento di apertura del turno sono passati più di 24 ore. Prima di eseguire l''operazione è necessario aprire un nuovo turno di cassa.';
				|pl = 'Minęło ponad 24 godziny od otwarcia zmiany. Przed wykonaniem operacji należy otworzyć nową zmianę kasową.';
				|tr = 'Vardiyanın açılmasından bu yana 24 saatten fazla zaman geçmiştir. İşlemin gerçekleştirilebilmesi için yeni bir POS vardiyası açılmalıdır.'"), Buttons);
		Return;
		
	ElsIf Not Form.StructureRegisterShiftState.ShiftIsOpened
		And (Not Form.AccessRights.OpenShift Or Not Form.AccessRights.CloseShift) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Đã hơn 24 giờ kể từ khi mở ca. Trước khi thực hiện thao tác, bạn phải mở ca làm việc mới.';
				|ru = 'С момента открытия смены прошло более 24 часов. Перед выполнением операции требуется открыть новую кассовую смену.';
				|en = 'More than 24 hours have passed since the shift was opened. It is required to open a new POS shift before executing the operation.'; fa = 'More than 24 hours have passed since the shift was opened. It is required to open a new POS shift before executing the operation.';
				|it = 'Dal momento di apertura del turno sono passati più di 24 ore. Prima di eseguire l''operazione è necessario aprire un nuovo turno di cassa.';
				|pl = 'Minęło ponad 24 godziny od otwarcia zmiany. Przed wykonaniem operacji należy otworzyć nową zmianę kasową.';
				|tr = 'Vardiyanın açılmasından bu yana 24 saatten fazla zaman geçmiştir. İşlemin gerçekleştirilebilmesi için yeni bir POS vardiyası açılmalıdır.'"));
		
		RunCallback(CallbackDescriptionCompletion, False);
		Return;
		
	EndIf;
	
	RunCallback(CallbackDescriptionCompletion, True);
	
EndProcedure

// Controls the parameters of the current cash change of equipment, if necessary, opens and closes the cash shift
// automatically.
//
// Parameters:
//  Equipment - CatalogRef.Peripherals
//  CallbackDescriptionCompletion - CallbackDescription - Description of the notification when the operation is completed.
//
Procedure HandleShiftStateAutomatically(Equipment, CallbackDescriptionCompletion = Undefined) Export
	
	Parameters = RetailSalesServerCall.GetShiftStateProcessingParameters(Equipment);
	
	If Not Parameters.StructureRegisterShiftState.ShiftIsOpened
		And Parameters.AccessRights.OpenShift Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NotificationProcessing", CallbackDescriptionCompletion);
		AdditionalParameters.Insert("CashRegisterParameters", Equipment);
		AdditionalParameters.Insert("Form", Parameters);
		
		StateManagementAndCommandProcessing("OpenRegisterShift", AdditionalParameters);
		
		Return;
		
	ElsIf Not Parameters.StructureRegisterShiftState.ShiftIsOpened
		And Not Parameters.AccessRights.OpenShift Then
		
		RunCallback(CallbackDescriptionCompletion, False);
		
		Return;
		
	EndIf;
	
	If Parameters.StructureRegisterShiftState.Error24Hours
		And Parameters.AccessRights.OpenShift
		And Parameters.AccessRights.CloseShift Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NotificationProcessing", CallbackDescriptionCompletion);
		AdditionalParameters.Insert("CashRegisterParameters", Equipment);
		AdditionalParameters.Insert("Form", Parameters);
		
		StateManagementAndCommandProcessing("CloseAndOpenCashShift", AdditionalParameters);
		
		Return;
		
	ElsIf Not Parameters.StructureRegisterShiftState.ShiftIsOpened
		And (Not Parameters.AccessRights.OpenShift Or Not Parameters.AccessRights.CloseShift) Then
		
		RunCallback(CallbackDescriptionCompletion, False);
		
		Return;
		
	EndIf;
	
	RunCallback(CallbackDescriptionCompletion, True);
	
EndProcedure

#EndRegion

#Region PaymentWithPaymentCards

// Calls payment procedures with a payment card
//
// Parameters:
//  ResultOfCarryingOut - Boolean - A sign of successful execution of the paid receipt of the CMC
//  AdditionalParameters - Structure:
//  	* Form - ClientApplicationForm - contains including:
//  		** POSTerminals - See Catalogs.POSTerminals.ParametersOfAcquiringTerminalsByOrganization
//  	* POSTerminals 	- ValueList of CatalogRef.Peripherals - Contains:
//  		** Value - CatalogRef.Peripherals
//  								- CatalogRef.Peripherals
//  	* CallbackOnCompletion - CallbackDescription
//  	* CashRegisterParameters - Structure
//  	* AuthorizationForm_Amount - Number
//  	* AuthorizationForm_AmountLimit - Number
//  	* Currency - CatalogRef.Currencies
//  	* StructureAcquiringTerminal - Structure
//  	
Procedure AddCardPayment(ResultOfCarryingOut, AdditionalParameters) Export
	
	If Not ResultOfCarryingOut Then
		RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
		Return;
	EndIf;
	
	If AdditionalParameters.POSTerminals.Count() = 1 Then
		
		PaymentByCardAfterCompletingSelectionOfAcquiringTerminal(
			AdditionalParameters.POSTerminals[0].Value,
			AdditionalParameters);
		
	ElsIf AdditionalParameters.POSTerminals.Count() > 1 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceList", New ValueList);
		
		For Each Terminal In AdditionalParameters.POSTerminals Do
			TerminalValue = Terminal.Value;
			FormParameters.ChoiceList.Add(TerminalValue, TerminalValue.Ref);
		EndDo;
		
		OpenForm(
			"Document.CashRegisterReceipt.Form.SelectPOSTerminal",
			FormParameters,,,,,
			New CallbackDescription(
				"PaymentByCardAfterCompletingSelectionOfAcquiringTerminal",
				RetailSalesClient, AdditionalParameters),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CancellationOfPaymentByPaymentCards

// Causes the cancellation of a payment card payment
//
// Parameters:
//  ResultOfCarryingOut - Boolean - A sign of successful execution of the paid receipt of the CMC
// 	AdditionalParameters - See AddCardPayment.AdditionalParameters
//
Procedure CancelCardPayment(ResultOfCarryingOut, AdditionalParameters) Export
	
	NotificationOnCompletion = AdditionalParameters.NotificationOnCompletion;
	CurrentData = AdditionalParameters.CurrentData;
	
	If Not ResultOfCarryingOut Then
		RunCallback(
			NotificationOnCompletion,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData", False, False, AdditionalParameters));
		Return;
	EndIf;
	
	ResultOfCardPaymentCancellation = StructureOfCardPaymentCancellationResult();
	ResultOfCardPaymentCancellation.TransactionAmount  = CurrentData.Sum;
	ResultOfCardPaymentCancellation.ReferenceNumber = CurrentData.ReferenceNumber;
	ResultOfCardPaymentCancellation.ReceiptNumber      = CurrentData.POSTerminalReceiptNumber;
	ResultOfCardPaymentCancellation.CardNumber     = CurrentData.PaymentCardNumber;
	ResultOfCardPaymentCancellation.AuthorizationCode = CurrentData.AuthorizationCode;
	ResultOfCardPaymentCancellation.PaymentLine_   = CurrentData;
	If AdditionalParameters.Property("AnyAmountReturnedToPaymentCard") Then
		ResultOfCardPaymentCancellation.AnyAmountReturnedToPaymentCard = AdditionalParameters.AnyAmountReturnedToPaymentCard; 
	EndIf;
	
	ResultOfCardPaymentCancellation.NotificationOnCompletion = NotificationOnCompletion;
	ResultOfCardPaymentCancellation.Form                   = AdditionalParameters.Form;
	
	TerminalUsedCorrespondsToSettings = False;
	IDOfETDevice = Undefined;
	For Each Terminal In AdditionalParameters.Form.POSTerminals Do
		TerminalValue = Terminal.Value;
		If TerminalValue.Ref = CurrentData.POSTerminal Then
			StructureAcquiringTerminal = TerminalValue;
			IDOfETDevice = StructureAcquiringTerminal.Peripherals;
			TerminalUsedCorrespondsToSettings = True;
			Break;
		EndIf;
	EndDo;
	
	If ValueIsFilled(IDOfETDevice)
		Or (StructureAcquiringTerminal <> Undefined
		   And StructureAcquiringTerminal.UseWithoutConnectingPeripherals) Then
		
		If Not StructureAcquiringTerminal.UseWithoutConnectingPeripherals Then
			ETResult = EquipmentManagerTMClient.EquipmentAttached(IDOfETDevice);
		Else
			ETResult = True;
		EndIf;
		
		If ETResult Then
			
			If Not StructureAcquiringTerminal.UseWithoutConnectingPeripherals Then
				
				OperationParametersList = PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation();
				OperationParametersList.TransactionType  = AdditionalParameters.TransactionType;
				OperationParametersList.TransactionAmount  = CurrentData.Sum;
				OperationParametersList.CardNumber     = "";
				OperationParametersList.ReceiptNumber      = CurrentData.POSTerminalReceiptNumber;
				OperationParametersList.ReferenceNumber = CurrentData.ReferenceNumber;
				OperationParametersList.AuthorizationCode = CurrentData.AuthorizationCode;
				
				If AdditionalParameters.Property("DocumentBasis") Then
					OperationParametersList.DocumentBasis = AdditionalParameters.DocumentBasis;
				EndIf;
				
				Notification = New CallbackDescription(
					"AfterPerformingOperationOfCancelingPaymentByCardAtAcquiringTerminal",
					ThisObject,
					ResultOfCardPaymentCancellation);
				
				PeripheralsPaymentSystemsServerClient.StartOperationOnAcquiringTerminal(
					Notification,
					AdditionalParameters.Form.UUID,
					IDOfETDevice,
					OperationParametersList,
					,
					AdditionalParameters.CashRegisterParameters.DeviceID);
				
			Else
				
				QueryText = NStr("vi = 'Cần thực hiện giao dịch hủy thanh toán bằng thiết bị thẻ thanh toán.';
								|ru = 'Требуется выполнить операцию отмены оплаты на эквайринговом терминале.';
								|en = 'Cancel POS terminal payment.'; fa = 'Cancel POS terminal payment.';
								|it = 'È necessario annullare l''operazione di pagamento eseguita con il terminale POS.';
								|pl = 'Wymagane jest wykonanie operacji anulowania płatności w terminalu nabywającym.';
								|tr = 'PoS terminalde bir ödeme iptal işlemi gerçekleştirmek için gereklidir.'") + Chars.LF;
				QueryText = QueryText + NStr("vi = 'Số tiền giao dịch:';
											|ru = 'Сумма операции:';
											|en = 'Transaction amount:'; fa = 'Transaction amount:';
											|it = 'Importo dell''operazione:';
											|pl = 'Ilość operacji:';
											|tr = 'İşlem tutarı:'")  + " "+ CurrentData.Sum               + Chars.LF;
				QueryText = QueryText + NStr("vi = 'Số thẻ:';
											|ru = 'Номер карты:';
											|en = 'Card number:'; fa = 'Card number:';
											|it = 'Numero della carta:';
											|pl = 'Numer karty:';
											|tr = 'Kart numarası:'")     + " "+ CurrentData.PaymentCardNumber + Chars.LF;
				QueryText = QueryText + NStr("vi = 'Số tham chiếu:';
											|ru = 'Ссылочный номер:';
											|en = 'Reference number:'; fa = 'Reference number:';
											|it = 'Numero di riferimento:';
											|pl = 'Numer referencyjny:';
											|tr = 'Referans numarası:'") + " "+ CurrentData.ReferenceNumber      + Chars.LF;
				QueryText = QueryText + NStr("vi = 'Số phiếu:';
											|ru = 'Номер чека:';
											|en = 'Receipt number:'; fa = 'Receipt number:';
											|it = 'Numero della ricevuta di cassa:';
											|pl = 'Numer paragonu:';
											|tr = 'Fiş numarası:'")      + " "+ CurrentData.POSTerminalReceiptNumber         + Chars.LF;
				QueryText = QueryText + Chars.LF;
				QueryText = QueryText + NStr("vi = 'Giao dịch hủy bỏ thanh toán trên thiết bị thanh toán thẻ đã diễn ra thành công?';
											|ru = 'Операция отмены оплаты на эквайринговом терминале прошла успешно?';
											|en = 'Was the POS terminal payment cancellation transaction successful?'; fa = 'Was the POS terminal payment cancellation transaction successful?';
											|it = 'L''annullamento del pagamento al terminale POS è avvenuta con successo?';
											|pl = 'Czy operacja anulowania płatności w terminalu przejmującym się powiodła?';
											|tr = 'PoS terminaldeki ödeme iptal işlemi başarılı mıydı?'");
				
				ShowQueryBox(
					New CallbackDescription(
						"CancelingCardPaymentAfterCompletingAuthorization",
						RetailSalesClient,
						ResultOfCardPaymentCancellation),
					QueryText,
					QuestionDialogMode.YesNo);
				
			EndIf;
			
		Else
			MessageText = NStr("vi = 'Chưa kết nối thiết bị thanh toán thẻ. Chưa thực hiện giao dịch theo thẻ.';
								|ru = 'Эквайринговый терминал не подключен. Операция по карте не выполнена.';
								|en = 'POS terminal is not connected. Card transaction failed.'; fa = 'POS terminal is not connected. Card transaction failed.';
								|it = 'Il terminale POS non è connesso. La transazione con la carta è fallita.';
								|pl = 'Terminal płatności nie jest połączony. Operacja na karcie nie powiodła się.';
								|tr = 'PoS terminali bağlı değil. Kart işlemi gerçekleştirilmedi.'");
			RetailSalesServerCall.LogEntry(MessageText, "CancelCardPayment");
			CommonClient.MessageToUser(MessageText);
			
			RunCallback(
				NotificationOnCompletion,
				New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData", False, False, AdditionalParameters));
			
		EndIf;
		
	Else
		
		OperationResult = New Structure;
		OperationResult.Insert("OperationPerformedOnDevice", False);
		OperationResult.Insert("ModifiedDataIsRecorded", False);
		OperationResult.Insert("CardPaymentCancellationData", AdditionalParameters);
		OperationResult.Insert("TerminalUsedCorrespondsToSettings", TerminalUsedCorrespondsToSettings);
		
		RunCallback(NotificationOnCompletion, OperationResult);
		
	EndIf;
	
EndProcedure

#EndRegion

// Closes the CCT verification session
//
// Parameters:
//  UUID - See EquipmentManagerClient.StartClosingRegistrationSession.UUID 
// 	DeviceID - See EquipmentManagerClient.MarkingCodeVerificationSession.DeviceID
//
Procedure CloseKmVerificationSessionOnCCT(UUID, DeviceID) Export
	
	If EquipmentManagerClient.MarkingCodeVerificationSession(DeviceID) <> Undefined Then
		NotificationOnCompletion = New CallbackDescription("CloseKmVerificationSessionOnCCTCompletion", ThisObject);
		EquipmentManagerClient.StartClosingRegistrationSession(NotificationOnCompletion, UUID, , DeviceID);
	EndIf;
	
EndProcedure

// Method for handling notification about the End of operation of serial connection of equipment when opening the form. It is used in CWP forms paired with
// See EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm
// It is triggered every time after connecting the next device. 
//
// Parameters:
//  Data - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware 
//  AdditionalParameters - Structure:
//   *Form - ClientApplicationForm
//
Procedure StartConnectingDevicesWhenYouOpenFormCompletion(Data, AdditionalParameters) Export
	
	ConnectionStatus = 1;
	FilterForSearch = New Structure("Ref", Data.DeviceID);
	If Data.Result Then
		ConnectionStatus = 0;
	Else
		ReportErrorOfOperationOnDevice(Data.DeviceID, "ConnectingDevice", Data.ErrorDescription);
	EndIf;
	
	For Each TSRow In AdditionalParameters.Form.Equipment.FindRows(FilterForSearch) Do
		TSRow.Attached = ConnectionStatus;
	EndDo;
	
	Notify("EquipmentAttached", New Structure("HardwareId,Attached", Data.DeviceID, ConnectionStatus), AdditionalParameters.Form);
	
EndProcedure

// Displays an error message to the user when performing of operation on the device.
//
// Parameters:
//  Device - CatalogRef.Peripherals
//  OperationToken - String - Supported values: Device connection, Device disconnection
//  ErrorDescription - String -
//  PathToTabularSection - String
//
Procedure ReportErrorOfOperationOnDevice(Device, OperationToken, ErrorDescription, PathToTabularSection="") Export

	If OperationToken = "ConnectingDevice" Then
		MessageText = NStr("vi = 'Khi kết nối thiết bị %Device% đã xảy ra lỗi:
		                            |""%ErrorDescription%"".';
		                            |ru = 'При подключении устройства %Device% произошла ошибка:
		                            |""%ErrorDescription%"".';
		                            |en = 'An error occurred when connecting the %Device% device:
		                            |""%ErrorDescription%"".'; fa = 'An error occurred when connecting the %Device% device:
		                            |""%ErrorDescription%"".';
		                            |it = 'Si è verificato un errore durante il collegamento dell''apparecchiatura%Device%:
		                            | ""%ErrorDescription%"".';
		                            |pl = 'Podczas podłączenia urządzenia %Device% wystąpił błąd:
		                            |""%ErrorDescription%"".';
		                            |tr = 'Cihaz bağlanırken hata oluştu:%Device%
		                            |""%ErrorDescription%"".'");
	ElsIf OperationToken = "DisablingDevice" Then
		MessageText = NStr("vi = 'Khi tắt thiết bị %Device% đã xảy ra lỗi:
		                            |""%ErrorDescription%"".';
		                            |ru = 'При отключении устройства %Device% произошла ошибка:
		                            |""%ErrorDescription%"".';
		                            |en = 'An error occurred when disconnecting the %Device% device:
		                            |""%ErrorDescription%"".'; fa = 'An error occurred when disconnecting the %Device% device:
		                            |""%ErrorDescription%"".';
		                            |it = 'Si è verificato un errore durante lo scollegamento dell''apparecchiatura %Device%: 
		                            | ""%ErrorDescription%"".';
		                            |pl = 'Podczas odłączenia urządzenia %Device% wystąpił błąd:
		                            |""%ErrorDescription%"".';
		                            |tr = '%Device%cihaz bağlantısı kesilirken bir hata oluştu:
		                            |""%ErrorDescription%"".'");
	Else
		MessageText = NStr("vi = 'Khi thực hiện giao dịch trên thiết bị %Device% đã xảy ra lỗi:
		                            |""%ErrorDescription%"".';
		                            |ru = 'При выполнении операции на устройстве %Device% произошла ошибка:
		                            |""%ErrorDescription%"".';
		                            |en = 'An error occurred when performing the operation on the %Device% device:
		                            |""%ErrorDescription%"".'; fa = 'An error occurred when performing the operation on the %Device% device:
		                            |""%ErrorDescription%"".';
		                            |it = 'При выполнении операции на устройстве %Device% произошла ошибка:
		                            |""%ErrorDescription%"".';
		                            |pl = 'An error occurred when performing the operation on the %Device% device:
		                            |""%ErrorDescription%"".';
		                            |tr = '%Device% cihazında işlem gerçekleştirilirken hata oluştu:
		                            |""%ErrorDescription%"".'");
	EndIf;
	
	MessageText = StrReplace(MessageText, "%ErrorDescription%", ErrorDescription);
	MessageText = StrReplace(MessageText, "%Device%",     Device);
	
	CommonClient.MessageToUser(MessageText,
		,
		PathToTabularSection,
		,
		False);
	
EndProcedure

// Opens the Connected equipment form, called from forms of different CWP
//
// Parameters:
//  Form - ClientApplicationForm
//  ConnectEquipmentOnOpening - Boolean
//
Procedure OpenConnectedHardwareForm(Form, ConnectEquipmentOnOpening = True) Export
	
	ClearMessageWindow(Form);
	OpeningParameters = New Structure;
	OpeningParameters.Insert("UUID",           Form.UUID);
	OpeningParameters.Insert("ConnectEquipmentOnOpening", ConnectEquipmentOnOpening);
	OpeningParameters.Insert("SupportedPeripheralTypes", Form.SupportedPeripheralTypes);
	
	If Form.FormName = "Document.CashRegisterReceipt.Form.CWPDocumentForm" Then
		
		OnCloseNotifyDescription = New CallbackDescription(
			"StartConnectingDevicesWhenYouOpenFormCompletion",
			Form);
		
		OpenForm(
			"Document.CashRegisterReceipt.Form.Peripherals_",
			OpeningParameters,
			Form,
			Form.UUID,,,
			OnCloseNotifyDescription);
			
	Else
		
		OpenForm(
			"Document.CashRegisterReceipt.Form.Peripherals_",
			OpeningParameters,
			Form,
			Form.UUID);
		
	EndIf;
	
EndProcedure

// Performs notification processing when the equipment is connected. It is called from the CWP forms
//
// Parameters:
//  Form - ClientApplicationForm
//  Parameter - Structure:
//   *HardwareId - CatalogRef.Peripherals
//   *Attached - Number -
//  Source - Arbitrary
//
Procedure ProcessHardwareConnectedEvent(Form, Parameter, Source) Export
	
	If TypeOf(Source) = Type("ClientApplicationForm") 
		And Source.FormName = "Document.CashRegisterReceipt.Form.Peripherals_"
		And TypeOf(Parameter) = Type("Structure") Then
		
		ConnectionStatusForReplacement = 1 - Parameter.Attached;
		HardwareStrings = Form.Equipment.FindRows(New Structure("Ref,Attached", Parameter.HardwareId, ConnectionStatusForReplacement));
		For Each HardwareString In HardwareStrings Do
			HardwareString.Attached = Parameter.Attached;
		EndDo;
		
	EndIf;
	
EndProcedure

// Requests user confirmation to cancel the document.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  NotificationDetailsCompletion - CallbackDescription -
//
Procedure DisplayQuestionAboutNeedForUnverifiedDocument(Form, NotificationDetailsCompletion) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationDetailsCompletion", NotificationDetailsCompletion);
	AdditionalParameters.Insert("Form", Form);
	ShowQueryBox(
		New CallbackDescription("AfterAnsweringQuestionAboutCancellationOfDocument", ThisObject, AdditionalParameters),
		NStr("vi = 'Chỉ có thể thực hiện giao dịch với chứng từ chưa kết chuyển, hủy kết chuyển chứng từ?';
			|ru = 'Операция возможна только с непроведенным документом, отменить проведение документа?';
			|en = 'The transaction is supported only for an unposted document. Do you want to unpost the document?'; fa = 'The transaction is supported only for an unposted document. Do you want to unpost the document?';
			|it = 'L''operazione è possibile solo con documenti non pubblicati, annullare la pubblicazione del documento?';
			|pl = 'Operacja jest możliwa tylko z niezatwierdzonym dokumentem, anulować zatwierdzenie dokumentu?';
			|tr = 'Bir işlem yalnızca kaydedilmemiş bir belge ile mümkündür, belgenin kaydını kaldır?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

// Checks the possibility of adding payment with bonus points.
// Parameters:
//  Form - ClientApplicationForm - 
//  CheckStatusOfEvent - Boolean -
//  
// Returns:
//  Boolean -
//
Function CheckPossibilityOfAddingPaymentWithBonusPoints(Form, CheckStatusOfEvent = True) Export
	Result = True;
	
	ClearMessages();
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		If Form.Object.SubstituteGoods.Count() = 0 Then
			
			Result = False;
			MessageText = NStr("vi = 'Để thêm phương thức thanh toán bằng điểm thưởng, cần chỉ định một mặt hàng thay thế.';
								|ru = 'Для добавления оплаты бонусными баллами необходимо указать заменяющую позицию.';
								|en = 'To add a payment with bonus points, specify substitute goods.'; fa = 'To add a payment with bonus points, specify substitute goods.';
								|it = 'Для добавления оплаты бонусными баллами необходимо указать заменяющую позицию.';
								|pl = 'To add a payment with bonus points, specify substitute goods.';
								|tr = 'Bonus puanlarla ödeme eklemek için yedek pozisyon belirtmeniz gerekmektedir.'");
			CommonClient.MessageToUser(MessageText,,,);
			
		ElsIf ValueIsFilled(Form.Object.Ref) 
				And RetailSalesServerCall.ShipmentHasBeenMadeBasedOnOrder(Form.Object.Ref) Then
					
			Result = False;
			MessageText = NStr("vi = 'Tạo chứng từ trên cơ sở giấy đề nghị. Không thể thêm phương thức thanh toán bằng điểm thưởng.';
								|ru = 'На основании заявки оформлена отгрузка. Добавить оплату бонусными баллами нельзя.';
								|en = 'The shipment is registered based on the request. Cannot add a payment with bonus points.'; fa = 'The shipment is registered based on the request. Cannot add a payment with bonus points.';
								|it = 'На основании заявки оформлена отгрузка. Добавить оплату бонусными баллами нельзя.';
								|pl = 'The shipment is registered based on the request. Cannot add a payment with bonus points.';
								|tr = 'Talebe istinaden sevkiyat oluşturuldu. Bonus puanlarla ödeme ekleyemezsiniz.'");
			CommonClient.MessageToUser(MessageText,,,);
			
		EndIf;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesOrder") Then
		If Form.Object.Goods.Count() = 0 Then
			
			Result = False;
			MessageText = NStr("vi = 'Để thêm phương thức thanh toán bằng điểm thưởng, hãy chỉ định ít nhất một mặt hàng.';
								|ru = 'Для добавления оплаты бонусными баллами укажите хотя бы одну номенклатурную позицию.';
								|en = 'To add a payment with bonus points, specify at least one item.'; fa = 'To add a payment with bonus points, specify at least one item.';
								|it = 'Для добавления оплаты бонусными баллами укажите хотя бы одну номенклатурную позицию.';
								|pl = 'To add a payment with bonus points, specify at least one item.';
								|tr = 'Bonus puanlarla ödeme eklemek için en az bir ürün pozisyonu belirtin.'");
			CommonClient.MessageToUser(MessageText,,,);
			
		ElsIf ValueIsFilled(Form.Object.Ref) 
				And RetailSalesServerCall.ShipmentHasBeenMadeBasedOnOrder(Form.Object.Ref) Then
					
			Result = False;
			MessageText = NStr("vi = 'Đã tạo chứng từ giao hàng trên cơ sở đơn hàng. Không thể thêm phương thức thanh toán bằng điểm thưởng.';
								|ru = 'На основании заказа оформлена отгрузка. Добавить оплату бонусными баллами нельзя.';
								|en = 'The shipment is registered based on the order. Cannot add a payment with bonus points.'; fa = 'The shipment is registered based on the order. Cannot add a payment with bonus points.';
								|it = 'На основании заказа оформлена отгрузка. Добавить оплату бонусными баллами нельзя.';
								|pl = 'The shipment is registered based on the order. Cannot add a payment with bonus points.';
								|tr = 'Siparişe istinaden sevkiyat oluşturuldu. Bonus puanlarla ödeme ekleyemezsiniz.'");
			CommonClient.MessageToUser(MessageText,,,);
			
		EndIf;
	EndIf;
	
	If CheckStatusOfEvent And Form.Object.Posted Then
		
		Result = False;
		MessageText = NStr("vi = 'Trước khi thêm phương thức thanh toán bằng điểm thưởng, cần hủy kết chuyển chứng từ.';
							|ru = 'Перед добавлением оплаты бонусными баллами необходимо отменить проведение документа.';
							|en = 'To add a payment with bonus points, unpost the document first.'; fa = 'To add a payment with bonus points, unpost the document first.';
							|it = 'Перед добавлением оплаты бонусными баллами необходимо отменить проведение документа.';
							|pl = 'To add a payment with bonus points, unpost the document first.';
							|tr = 'Bonus puanlarla ödeme eklemeden önce belgeyi iptal etmeniz gerekmektedir.'");
		CommonClient.MessageToUser(MessageText,,,);
		
	EndIf;
	
	Return Result
EndFunction

// Requests confirmation of operation changes when the checkout closes the shift.
// Parameters:
//  Form - ClientApplicationForm -
//  CallbackOnCompletion - CallbackDescription -
// 
// Returns:
//  Boolean -
//
Function RequestConfirmationOfOperationChangesWhenClosingCashierShift(Form, CallbackOnCompletion) Export
	
	Result = False;
	OperationBeforeChange = TMCommonUseClientServer.GetValueBeforeChange(Form, Form.Items.TransactionOnRegisterShiftEndClosing.Name);
	If OperationBeforeChange = PredefinedValue("Enum.TransactionsOnRegisterShiftEndClosing.None")
		And Form.ConstantsSet.TransactionOnRegisterShiftEndClosing <> OperationBeforeChange Then
		Result = True;
		QueryText = NStr("vi = 'Chế độ làm việc này không được khuyến nghị và không còn hỗ trợ nữa.
						|Sau khi thay đổi chế độ, sẽ không thể quay lại tùy chỉnh hiện tại. Tiếp tục?';
						|ru = 'Текущий режим работы не является рекомендуемым и более не поддерживается.
						|После изменения режима возврат к текущей настройке будет недоступен. Продолжить?';
						|en = 'The current operation mode is not recommended and is no longer supported.
						| After the modification of the current mode, a rollback to the previous setting will become unavailable. Continue?'; fa = 'The current operation mode is not recommended and is no longer supported.
						| After the modification of the current mode, a rollback to the previous setting will become unavailable. Continue?';
						|it = 'Текущий режим работы не является рекомендуемым и более не поддерживается.
						|После изменения режима возврат к текущей настройке будет недоступен. Продолжить?';
						|pl = 'The current operation mode is not recommended and is no longer supported.
						| After the modification of the current mode, a rollback to the previous setting will become unavailable. Continue?';
						|tr = 'Mevcut çalışma modu önerilmemektedir ve artık desteklenmemektedir.
						|Modu değiştirdikten sonra geçerli ayara geri dönülemeyecektir. Devam edilsin mi?'");
		ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Region Private

Procedure OpenReportsTabForChangingFormOfPOSShiftDocument(Document)
	
	If ValueIsFilled(Document) Then
		OpenForm("Document.CashRegisterShift.ObjectForm", New Structure("Key,OpenShiftReportsTab", Document, True));
	EndIf;
	
EndProcedure

Procedure TellUserDescriptionOfErrorWhenClosingPOSShift(ErrorDescription)

	// The error text should appear in the open document window.
	If ValueIsFilled(ErrorDescription) Then
		MessageText = NStr("vi = 'Đóng phiên làm việc trên máy ghi nhận tiền mặt.
								|Mô tả bổ sung:
								|%AdditionalDetails%';
								|ru = 'Смена закрыта на фискальном регистраторе.
								|Дополнительное описание:
								|%AdditionalDetails%';
								|en = 'Shift is closed on fiscal cash register.
								|Additional details:
								|%AdditionalDetails%'; fa = 'Shift is closed on fiscal cash register.
								|Additional details:
								|%AdditionalDetails%';
								|it = 'Il turno è chiuso sul registratore fiscale.
								|Ulteriore descrizione:
								|%AdditionalDetails%';
								|pl = 'Zmiana zamknięta na fiskalnym rejestratorze.
								|Dodatkowy opis:
								|%AdditionalDetails%';
								|tr = 'Vardiya mali kayıt defterinde kapalıdır.
								|Ek ayrıntılar:
								|%AdditionalDetails%'");
		MessageText = StrReplace(MessageText, "%AdditionalDetails%", ErrorDescription);
		CommonClient.MessageToUser(MessageText);
	EndIf;

EndProcedure

Procedure GenerateReportOnRetailSales(Object)
	
	ErrorDescription = "";
	DocumentsArray = RetailSalesServerCall.CloseRegisterShift(Object, False, ErrorDescription);
	
	For Each Document In DocumentsArray Do
		
		If TypeOf(Document) = Type("DocumentRef.CashRegisterShift") Then
			OpenReportsTabForChangingFormOfPOSShiftDocument(Document);
		EndIf;
		
	EndDo;
	
	TellUserDescriptionOfErrorWhenClosingPOSShift(ErrorDescription);
	
	Notify("Write_RetailSalesReport", New Structure, DocumentsArray);
	
EndProcedure

Procedure AfterAnsweringQuestionAboutCancellationOfDocument(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		CallbackDescription = New CallbackDescription("AfterAnsweringQuestionAboutCancellationOfDocumentCompletion", ThisObject, AdditionalParameters);
		TMPeripheralsClient.WriteObject(
			AdditionalParameters.Form,
			DocumentWriteMode.UndoPosting,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

Procedure AfterAnsweringQuestionAboutCancellationOfDocumentCompletion(Result, AdditionalParameters) Export
	
	// Returns the result of executing the method of the managed application form Write
	If Result = True Then
		RunCallback(AdditionalParameters.NotificationDetailsCompletion, True);
	EndIf;
	
EndProcedure

// Removes the sign that the form is available, if it is set.
// Parameters:
//  Form - ClientApplicationForm
//
Procedure LockForm(Form) Export
	
	If Form.Enabled = True Then
		Form.Enabled = False;
	EndIf;
	
EndProcedure

// Sets whether the form is available if it is not set.
// Parameters:
//  Form - ClientApplicationForm
//
Procedure UnblockForm(Form) Export
	
	If Form.Enabled = False Then
		Form.Enabled = True;
	EndIf;
	
EndProcedure

// Clears the user's message window and for forms of documents that are CWP, clears the text of the error message when printing the receipt.
//
// Parameters:
//  Form - ClientApplicationForm - 
//
Procedure ClearMessageWindow(Form) Export
	ClearMessages();
	If RetailSalesClientServer.NamesOfCWPForms().Find(Form.FormName) <> Undefined Then
		If Form.Items.InformationPanelGroupErrorWhenPrintingReceipt.Visible Then
			Form.Items.InformationPanelErrorWhenPrintingReceipt.Title = "";
			Form.InformationPanelErrorWhenPrintingReceiptText = "";
			Form.Items.InformationPanelGroupErrorWhenPrintingReceipt.Visible = False;
		EndIf;
	EndIf;	
EndProcedure

// Notifies about an error when printing a receipt in the CWP form.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  ExecutionResult - Structure - 
//  WriteToLog_ - Boolean -
//
Procedure ReportErrorWhenPrintingReceipt(Form, ExecutionResult, WriteToLog_ = True) Export
	If Form.FormName = RetailSalesClientServer.NamesOfCWPForms().Find(Form.FormName) <> Undefined Then
		MaxNumberOfMessageCharacters = 512;
		MaxNumberOfMessageLines = 5;
		
		MessageText = NStr("vi = 'Đã xảy ra lỗi, khi in phiếu. Phiếu không được in trên thiết bị ghi nhận tiền mặt.
									|Mô tả bổ sung: %AdditionalDetails%';
									|ru = 'При печати чека произошла ошибка. Чек не напечатан на фискальном устройстве.
									|Дополнительное описание: %AdditionalDetails%';
									|en = 'An error occurred when printing a receipt. The receipt is not printed on a fiscal device.
									|Additional description: %AdditionalDetails%'; fa = 'An error occurred when printing a receipt. The receipt is not printed on a fiscal device.
									|Additional description: %AdditionalDetails%';
									|it = 'An error occurred when printing a receipt. The receipt is not printed on a fiscal device.
									|Additional description: %AdditionalDetails%';
									|pl = 'An error occurred when printing a receipt. The receipt is not printed on a fiscal device.
									|Additional description: %AdditionalDetails%';
									|tr = 'Fiş yazdırılırken hata oluştu. Fiş, mali cihazda yazdırılmadı.
									|Ek ayrıntılar: %AdditionalDetails%'");
		MessageText = StrReplace(
								MessageText,
								"%AdditionalDetails%",
								ExecutionResult.ErrorDescription);
					
		Form.InformationPanelErrorWhenPrintingReceiptText = MessageText;
		
		HyperlinkShowInFull = False;
		If StrLen(MessageText) > MaxNumberOfMessageCharacters Then
			HyperlinkShowInFull = True;
			MessageText = Left(MessageText, MaxNumberOfMessageCharacters);	
		EndIf;
		
		If StrLineCount(MessageText) > MaxNumberOfMessageLines Then
			HyperlinkShowInFull = True;				
			MessageStrings = StrSplit(MessageText,Chars.LF);
			For RowIndex = -MessageStrings.UBound() To -MaxNumberOfMessageLines Do
				MessageStrings.Delete(-RowIndex);
			EndDo;
			MessageText = StrConcat(MessageStrings, Chars.LF);
		EndIf;
		
		If HyperlinkShowInFull Then
			LineShowInFull = New FormattedString(NStr("vi = '(hiển thị toàn bộ)';
														|ru = '(показать полностью)';
														|en = '(show in full)'; fa = '(show in full)';
														|it = '(show in full)';
														|pl = '(show in full)';
														|tr = '(tamamen göster)'", CommonClient.DefaultLanguageCode()),,,, "ShowCompleteErrorWhenPrintingReceipt");
			MessageStrings = New Array;
			MessageStrings.Add(New FormattedString(MessageText));
			MessageStrings.Add(LineShowInFull);
			MessageText = New FormattedString(MessageStrings);
		EndIf;
		
		Form.Items.InformationPanelErrorWhenPrintingReceipt.Title = MessageText;
		Form.Items.InformationPanelGroupErrorWhenPrintingReceipt.Visible = True;
		If WriteToLog_ Then
			FormObject1 = Form.Object; // DocumentObject
			RetailSalesServerCall.LogEntry(
				MessageText, "PrintingReceipt_Completion", FormObject1.Ref);
		EndIf;
	EndIf;
EndProcedure

#Region ShiftStateManagement

Procedure StateManagementAndCommandProcessing(Result, AdditionalParameters) Export
	
	If Result = "Cancel" Then
		RunCallback(AdditionalParameters.NotificationProcessing, False);
		Return;
	EndIf;
	
	If Result = "OpenRegisterShift" Then
		OpenRegisterShift(
			AdditionalParameters.CashRegisterParameters,
			New CallbackDescription("ManageShiftStateAfterOpeningCashShift", RetailSalesClient, AdditionalParameters));
	EndIf;
	
	If Result = "CloseAndOpenCashShift" Then
		CloseRegisterShift(
			AdditionalParameters.CashRegisterParameters,
			New CallbackDescription("ManageShiftStateAfterCashShiftCloses", RetailSalesClient, AdditionalParameters));
	EndIf;
	
EndProcedure

Procedure ManageShiftStateAfterCashShiftCloses(Result, AdditionalParameters) Export
	
	If Result Then
		
		If TypeOf(AdditionalParameters.CashRegisterParameters) = Type("Structure")
			Or TypeOf(AdditionalParameters.CashRegisterParameters) = Type("FixedStructure") Then
			CashRegisterCashRegisterFiscalDevice = AdditionalParameters.CashRegisterParameters.CashRegister;
		Else
			CashRegisterCashRegisterFiscalDevice = AdditionalParameters.CashRegisterParameters;
		EndIf;
		
		AdditionalParameters.Form.StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(CashRegisterCashRegisterFiscalDevice);
		
		If TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form, "Object")
			And TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form.Object, "Cashier") Then
			FillPropertyValues(AdditionalParameters.Form.Object, AdditionalParameters.Form.StructureRegisterShiftState,,"Cashier");
		ElsIf TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form, "Object") Then
			FillPropertyValues(AdditionalParameters.Form.Object, AdditionalParameters.Form.StructureRegisterShiftState);
		EndIf;
		
		If Not AdditionalParameters.Form.StructureRegisterShiftState.ShiftIsOpened Then
			RetailSalesClient.OpenRegisterShift(AdditionalParameters.CashRegisterParameters, AdditionalParameters.NotificationProcessing);
		Else
			RunCallback(AdditionalParameters.NotificationProcessing, False);
		EndIf;
		
	Else
		RunCallback(AdditionalParameters.NotificationProcessing, False);
	EndIf;
	
EndProcedure

Procedure ManageShiftStateAfterOpeningCashShift(Result, AdditionalParameters) Export
	
	If Result Then
		
		If TypeOf(AdditionalParameters.CashRegisterParameters) = Type("Structure")
			Or TypeOf(AdditionalParameters.CashRegisterParameters) = Type("FixedStructure") Then
			CashRegisterCashRegisterFiscalDevice = AdditionalParameters.CashRegisterParameters.CashRegister;
		Else
			CashRegisterCashRegisterFiscalDevice = AdditionalParameters.CashRegisterParameters;
		EndIf;
		
		AdditionalParameters.Form.StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(CashRegisterCashRegisterFiscalDevice);
		
		If TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form, "Object")
			And TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form.Object, "Cashier") Then
			FillPropertyValues(AdditionalParameters.Form.Object, AdditionalParameters.Form.StructureRegisterShiftState,,"Cashier");
		ElsIf TMCommonUseClientServer.HasObjectAttribute(AdditionalParameters.Form, "Object") Then
			FillPropertyValues(AdditionalParameters.Form.Object, AdditionalParameters.Form.StructureRegisterShiftState);
		EndIf;
		
		RunCallback(AdditionalParameters.NotificationProcessing, True);
		
	Else
		
		RunCallback(AdditionalParameters.NotificationProcessing, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PaymentWithPaymentCards

Function StructureOfCardPaymentResult()
	
	CardPaymentResult = New Structure;
	CardPaymentResult.Insert("POSTerminal");
	CardPaymentResult.Insert("CardNumber");
	CardPaymentResult.Insert("TransactionAmount");
	CardPaymentResult.Insert("ReferenceNumber");
	CardPaymentResult.Insert("ReceiptNumber");
	CardPaymentResult.Insert("AuthorizationCode");
	
	CardPaymentResult.Insert("CallbackOnCompletion");
	
	Return CardPaymentResult;
	
EndFunction

Procedure PaymentByCardAfterCompletingSelectionOfAcquiringTerminal(StructureAcquiringTerminal, AdditionalParameters) Export
	
	If StructureAcquiringTerminal <> Undefined Then
		IDOfETDevice = StructureAcquiringTerminal.Peripherals;
	Else
		IDOfETDevice = Undefined;
	EndIf;
	
	AdditionalParameters.IDOfETDevice      = IDOfETDevice;
	AdditionalParameters.StructureAcquiringTerminal = StructureAcquiringTerminal;
	
	If ValueIsFilled(IDOfETDevice)
		Or (StructureAcquiringTerminal <> Undefined
		   And StructureAcquiringTerminal.UseWithoutConnectingPeripherals) Then
		
		If Not StructureAcquiringTerminal.UseWithoutConnectingPeripherals Then
			ETResult = EquipmentManagerTMClient.EquipmentAttached(IDOfETDevice);
		Else
			ETResult = True;
		EndIf;
		
		If ETResult Then
			
			FormParameters = New Structure;
			FormParameters.Insert("Sum",       AdditionalParameters.AuthorizationForm_Amount);
			FormParameters.Insert("AmountLimit", AdditionalParameters.AuthorizationForm_AmountLimit);
			FormParameters.Insert("Currency",      AdditionalParameters.Currency);
			
			If StructureAcquiringTerminal.UseWithoutConnectingPeripherals Then
				FormParameters.Insert("ShowCardNumber", Not StructureAcquiringTerminal.DoNotAskForCardNumber);
			EndIf;
			
			OpenForm(
				"Catalog.Peripherals.Form.POSTerminalAuthorizationForm", FormParameters,,,,,
				New CallbackDescription(
					"AddCardPaymentCompletion",
					RetailSalesClient,
					AdditionalParameters),
				FormWindowOpeningMode.LockOwnerWindow);
			
		Else
			
			MessageText = NStr("vi = 'Chưa kết nối thiết bị thanh toán thẻ. Chưa thực hiện giao dịch theo thẻ.';
								|ru = 'Эквайринговый терминал не подключен. Операция по карте не выполнена.';
								|en = 'POS terminal is not connected. Card transaction failed.'; fa = 'POS terminal is not connected. Card transaction failed.';
								|it = 'Il terminale POS non è connesso. La transazione con la carta è fallita.';
								|pl = 'Terminal płatności nie jest połączony. Operacja na karcie nie powiodła się.';
								|tr = 'PoS terminali bağlı değil. Kart işlemi gerçekleştirilmedi.'");
			RetailSalesServerCall.LogEntry(
				MessageText, "PaymentByCardAfterCompletingSelectionOfAcquiringTerminal"); 
			CommonClient.MessageToUser(MessageText);
			
			RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
			
		EndIf;
		
	Else
		
		// The acquiring terminal is not selected
		
		RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - Structure
// 	AdditionalParameters - See AddCardPayment.AdditionalParameters
//
Procedure AddCardPaymentCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
		Return;
	EndIf;
	
	If AdditionalParameters.Property("JustFillInResultOfCardPayment") 
		And AdditionalParameters.JustFillInResultOfCardPayment = True Then
	
		If Not (TypeOf(Result) = Type("Structure")
			And Result.Property("Sum")
			And Result.Property("ReceiptNumber")
			And Result.Property("CardNumber")
			And Result.Property("ReferenceNumber")) Then

			RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
			Return;
		EndIf;

		CardPaymentResult = StructureOfCardPaymentResult();
		CardPaymentResult.POSTerminal = AdditionalParameters.StructureAcquiringTerminal.Ref;
		CardPaymentResult.CardNumber            = Result.CardNumber;
		CardPaymentResult.TransactionAmount         = Result.Sum;
		CardPaymentResult.ReceiptNumber             = Result.ReceiptNumber;
		CardPaymentResult.ReferenceNumber        = Result.ReferenceNumber;
		CardPaymentResult.AuthorizationCode        = Undefined;

		RunCallback(AdditionalParameters.CallbackOnCompletion, CardPaymentResult);		
		
	ElsIf Not AdditionalParameters.StructureAcquiringTerminal.UseWithoutConnectingPeripherals Then
		
		If Not (TypeOf(Result) = Type("Structure")
			And Result.Property("Sum")
			And Result.Property("ReceiptNumber")
			And Result.Property("ReferenceNumber")) Then
			
			RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
			Return;
		EndIf;
		
		PerformanceMonitorClient.TimeMeasurement("RetailSalesClient.AddCardPaymentCompletion");
		
		OperationParametersList = PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation();
		OperationParametersList.TransactionType  = "AuthorizeSales";
		OperationParametersList.TransactionAmount  = Result.Sum;
		OperationParametersList.ReceiptNumber      = Result.ReceiptNumber;
		OperationParametersList.ReferenceNumber = Result.ReferenceNumber;
		
		If AdditionalParameters.Property("DocumentBasis") Then
			OperationParametersList.DocumentBasis = AdditionalParameters.DocumentBasis;
		EndIf;
		
		Notification = New CallbackDescription("AfterPerformingCardPaymentOperationAtAcquiringTerminal", ThisObject, AdditionalParameters);
		PeripheralsPaymentSystemsServerClient.StartOperationOnAcquiringTerminal(
			Notification,
			AdditionalParameters.Form.UUID,
			AdditionalParameters.IDOfETDevice,
			OperationParametersList,
			,
			AdditionalParameters.CashRegisterParameters.DeviceID);
		
	Else
		
		If Not (TypeOf(Result) = Type("Structure")
			And Result.Property("Sum")
			And Result.Property("ReceiptNumber")
			And Result.Property("CardNumber")
			And Result.Property("ReferenceNumber")) Then
			
			RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
			Return;
		EndIf;
		
		QueryText = NStr("vi = 'Cần thực hiện giao dịch thanh toán bằng thiết bị thẻ thanh toán.';
						|ru = 'Требуется выполнить операцию оплаты на эквайринговом терминале.';
						|en = 'Payment on POS terminal is required.'; fa = 'Payment on POS terminal is required.';
						|it = 'È necessario eseguire l''operazione di pagamento con il terminale POS.';
						|pl = 'Chcesz wykonać operację płatności na terminalu płatności.';
						|tr = 'Bir PoS terminalinde ödeme işlemi gerçekleştirmek için gereklidir.'") + Chars.LF;
		QueryText = QueryText + NStr("vi = 'Số tiền giao dịch:';
									|ru = 'Сумма операции:';
									|en = 'Transaction amount:'; fa = 'Transaction amount:';
									|it = 'Importo dell''operazione:';
									|pl = 'Ilość operacji:';
									|tr = 'İşlem tutarı:'") + " "+ Result.Sum + Chars.LF;
		QueryText = QueryText + Chars.LF;
		QueryText = QueryText + NStr("vi = 'Đã thực hiện thành công giao dịch thanh toán bằng thiết bị thẻ thanh toán?';
									|ru = 'Операция оплаты на эквайринговом терминале прошла успешно?';
									|en = 'Was the transaction of payment via the POS terminal successful?'; fa = 'Was the transaction of payment via the POS terminal successful?';
									|it = 'L''operazione di pagamento con il terminale POS è avvenuta con successo?';
									|pl = 'Operacja płatności na terminalu płatności przebiegła pomyślnie?';
									|tr = 'PoS terminaldeki ödeme işlemi başarılı mıydı?'");
		
		CardPaymentResult = StructureOfCardPaymentResult();
		CardPaymentResult.POSTerminal = AdditionalParameters.StructureAcquiringTerminal.Ref;
		CardPaymentResult.CardNumber            = Result.CardNumber;
		CardPaymentResult.TransactionAmount         = Result.Sum;
		CardPaymentResult.ReceiptNumber             = Result.ReceiptNumber;
		CardPaymentResult.ReferenceNumber        = Result.ReferenceNumber;
		CardPaymentResult.AuthorizationCode        = Undefined;
		
		CardPaymentResult.CallbackOnCompletion = AdditionalParameters.CallbackOnCompletion;
		
		ShowQueryBox(
			New CallbackDescription(
				"PaymentByCardAfterQuestionAboutCompletionOfAuthorization",
				RetailSalesClient,
				CardPaymentResult),
			QueryText,
			QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	ExecutionResult - Structure
// 	AdditionalParameters - See AddCardPayment.AdditionalParameters
//
Procedure AfterPerformingCardPaymentOperationAtAcquiringTerminal(ExecutionResult, AdditionalParameters) Export
	
	If Not ExecutionResult.Result Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi thực hiện giao dịch, đã xảy ra lỗi:
			           |""%1"".
			           |Chưa thực hiện thanh toán theo thẻ.';
			           |ru = 'При выполнении операции возникла ошибка:
			           |""%1"".
			           |Оплата по карте не была произведена.';
			           |en = 'An error occurred while executing the transaction:
			           |""%1"".
			           |Payment by card was not performed.'; fa = 'An error occurred while executing the transaction:
			           |""%1"".
			           |Payment by card was not performed.';
			           |it = 'Durante l''esecuzione dell''operazione si è verificato un errore:
			           |""%1"". 
			           | Il pagamento con la carta non è stato effettuato.';
			           |pl = 'Podczas operacji wystąpił błąd:
			           |""%1"".
			           |Płatność na mapie nie została przeprowadzona.';
			           |tr = 'İşlem gerçekleştirilirken hata oluştu:
			           |""%1"".
			           |Kart ödemesi yapılmadı.'"),
			ExecutionResult.ErrorDescription);
		
		RetailSalesServerCall.LogEntry(
			MessageText, "AfterPerformingCardPaymentOperationAtAcquiringTerminal");
		CommonClient.MessageToUser(MessageText);
		
		RunCallback(AdditionalParameters.CallbackOnCompletion, Undefined);
		
	Else
		
		CardPaymentResult = StructureOfCardPaymentResult();
		CardPaymentResult.POSTerminal = AdditionalParameters.StructureAcquiringTerminal.Ref;
		CardPaymentResult.CardNumber            = ExecutionResult.CardNumber;
		CardPaymentResult.TransactionAmount         = ExecutionResult.TransactionAmount;
		CardPaymentResult.ReferenceNumber        = ExecutionResult.ReferenceNumber;
		CardPaymentResult.ReceiptNumber             = ExecutionResult.POSTerminalReceiptNumber;
		CardPaymentResult.AuthorizationCode        = ExecutionResult.AuthorizationCode;
		
		CardPaymentResult.CallbackOnCompletion = AdditionalParameters.CallbackOnCompletion;
		
		RunCallback(AdditionalParameters.CallbackOnCompletion, CardPaymentResult);
		
	EndIf;
	
EndProcedure

Procedure PaymentByCardAfterQuestionAboutCompletionOfAuthorization(QuestionResult, CardPaymentResult) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		RunCallback(CardPaymentResult.CallbackOnCompletion, CardPaymentResult);
		
	Else
		
		RunCallback(CardPaymentResult.CallbackOnCompletion, Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CancellationOfPaymentByPaymentCards

Function StructureOfCardPaymentCancellationResult()
	
	ResultOfCardPaymentCancellation = New Structure;
	ResultOfCardPaymentCancellation.Insert("TransactionAmount");
	ResultOfCardPaymentCancellation.Insert("ReferenceNumber");
	ResultOfCardPaymentCancellation.Insert("ReceiptNumber");
	ResultOfCardPaymentCancellation.Insert("CardNumber");
	ResultOfCardPaymentCancellation.Insert("AuthorizationCode");
	ResultOfCardPaymentCancellation.Insert("AnyAmountReturnedToPaymentCard", False);
	
	ResultOfCardPaymentCancellation.Insert("PaymentLine_");
	ResultOfCardPaymentCancellation.Insert("NotificationOnCompletion");
	ResultOfCardPaymentCancellation.Insert("Form");
	
	Return ResultOfCardPaymentCancellation;
	
EndFunction

Procedure CancelingCardPaymentAfterCompletingAuthorization(QuestionResult, ResultOfCardPaymentCancellation) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		RunCallback(
			New CallbackDescription("CancelPaymentByCreditCardCompletion", ResultOfCardPaymentCancellation.Form, ResultOfCardPaymentCancellation));
		
	Else
		
		RunCallback(
			ResultOfCardPaymentCancellation.NotificationOnCompletion,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData",
				False, False, ResultOfCardPaymentCancellation));
		
	EndIf;
	
EndProcedure

Procedure AfterPerformingOperationOfCancelingPaymentByCardAtAcquiringTerminal(ExecutionResult, ResultOfCardPaymentCancellation) Export
	
	If Not ExecutionResult.Result Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi thực hiện giao dịch, đã xảy ra lỗi:
			           |""%1"".
			           |Chưa thực hiện thanh toán theo thẻ.';
			           |ru = 'При выполнении операции возникла ошибка:
			           |""%1"".
			           |Отмена оплаты по карте не была произведена.';
			           |en = 'An error occurred while executing the transaction:
			           |""%1"".
			           |Payment by card was not canceled.'; fa = 'An error occurred while executing the transaction:
			           |""%1"".
			           |Payment by card was not canceled.';
			           |it = 'Durante l''esecuzione dell''operazione si è verificato un errore:
			           |""%1"". 
			           | Il pagamento non è stato annullato.';
			           |pl = 'Podczas operacji wystąpił błąd:
			           |""%1"".
			           |Anulowanie płatności na karcie nie zostało przeprowadzone.';
			           |tr = 'İşlem sırasında hata oluştu:
			           |""%1"".
			           |Kart ödemesi iptal edilmedi.'"),
			ExecutionResult.ErrorDescription);
		
		RetailSalesServerCall.LogEntry(
			MessageText, "AfterPerformingOperationOfCancelingPaymentByCardAtAcquiringTerminal");
		CommonClient.MessageToUser(MessageText);
		
		RunCallback(
			ResultOfCardPaymentCancellation.NotificationOnCompletion,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData",
				False, False, ResultOfCardPaymentCancellation));
		
	Else
		
		If ExecutionResult.Property("CardNumber") Then
			ResultOfCardPaymentCancellation.CardNumber = ExecutionResult.CardNumber;
		EndIf;
		If ExecutionResult.Property("ReferenceNumber") Then
			ResultOfCardPaymentCancellation.ReferenceNumber = ExecutionResult.ReferenceNumber;
		EndIf;
		If ExecutionResult.Property("POSTerminalReceiptNumber") Then
			ResultOfCardPaymentCancellation.ReceiptNumber = ExecutionResult.POSTerminalReceiptNumber;
		EndIf;
		If ExecutionResult.Property("AuthorizationCode") Then
			ResultOfCardPaymentCancellation.AuthorizationCode = ExecutionResult.AuthorizationCode;
		EndIf;
		
		RunCallback(
			New CallbackDescription("CancelPaymentByCreditCardCompletion", ResultOfCardPaymentCancellation.Form, ResultOfCardPaymentCancellation));
		
	EndIf;
	
EndProcedure

// Calls the operation of sequential cancellation of payment by payment cards.
// 
// Parameters:
//  Result - Boolean
//  AdditionalParameters - Structure, Undefined - 
// 
Procedure CancelPaymentByCreditCardsSequentially(Result, AdditionalParameters) Export
	
	If AdditionalParameters.PaymentLinesWithPaymentCards.Count() > 0 Then
		
		PaymentLine_ = AdditionalParameters.PaymentLinesWithPaymentCards[AdditionalParameters.PaymentLinesWithPaymentCards.Count() - 1];
		AdditionalParameters.PaymentLinesWithPaymentCards.Delete(AdditionalParameters.PaymentLinesWithPaymentCards.Find(PaymentLine_));

		CancellationOptions = New Structure;
		If AdditionalParameters.Property("Action") And AdditionalParameters.Action = "CancelPaymentsSequentially" Then
			CancellationOptions.Insert("NotificationOnCompletion", New CallbackDescription("CancelPaymentsByPaymentCardsCompletion", AdditionalParameters.Form, AdditionalParameters));
		Else		
			CancellationOptions.Insert("NotificationOnCompletion", New CallbackDescription("CancelPaymentByCreditCardsSequentially", RetailSalesClient, AdditionalParameters));
		EndIf;
		CancellationOptions.Insert("CurrentData",           PaymentLine_);
		CancellationOptions.Insert("Form",                   AdditionalParameters.Form);
		CancellationOptions.Insert("Currency",                  AdditionalParameters.Currency);
		CancellationOptions.Insert("CashRegisterParameters",       AdditionalParameters.CashRegisterParameters);
		CancellationOptions.Insert("TransactionType",           AdditionalParameters.TransactionType);
		
		If AdditionalParameters.Property("DocumentBasis") Then
			CancellationOptions.Insert("DocumentBasis", AdditionalParameters.DocumentBasis);
		EndIf;
		
		RunCallback(
			New CallbackDescription("CancelPaymentByCreditCard", AdditionalParameters.Form, CancellationOptions));
		
	Else
		
		RunCallback(
			AdditionalParameters.NotificationOnCompletion, Result);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	SelectionResult - Structure:
// 		* Action - String
// 		* RowSelected - FormDataCollectionItem
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm - 
// 
Procedure CancelPaymentByPaymentCardsSelectingPaymentLineCompletion(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult <> Undefined Then
		If SelectionResult.Action = "PaymentCancel" Then
			
			FilterParameters = New Structure;
			FilterParameters.Insert("AuthorizationCode");
			FilterParameters.Insert("PaymentCardNumber");
			FilterParameters.Insert("LineNumber");
			FilterParameters.Insert("POSTerminalReceiptNumber");
			FilterParameters.Insert("ReferenceNumber");
			FilterParameters.Insert("Sum");
			FilterParameters.Insert("POSTerminal");
			FillPropertyValues(FilterParameters, SelectionResult.RowSelected);
			
			PaymentWithPaymentCards = AdditionalParameters.Form.Object.PaymentWithPaymentCards;
			FoundRows = PaymentWithPaymentCards.FindRows(FilterParameters);
			
			If FoundRows.Count() > 0 Then
				
				CancellationOptions = New Structure;
				CancellationOptions.Insert(
					"NotificationOnCompletion",
					New CallbackDescription(
						"CancelPaymentsByPaymentCardsCompletion",
						AdditionalParameters.Form,
						AdditionalParameters));
				CancellationOptions.Insert("CurrentData",           FoundRows[0]);
				CancellationOptions.Insert("Form",                   AdditionalParameters.Form);
				CancellationOptions.Insert("Currency",                  AdditionalParameters.Currency);
				CancellationOptions.Insert("CashRegisterParameters",       AdditionalParameters.CashRegisterParameters);
				CancellationOptions.Insert("TransactionType",           AdditionalParameters.TransactionType);
				CancellationOptions.Insert(
					"AnyAmountReturnedToPaymentCard",
					AdditionalParameters.AnyAmountReturnedToPaymentCard);
				
				If AdditionalParameters.Property("DocumentBasis") Then
					CancellationOptions.Insert("DocumentBasis", AdditionalParameters.DocumentBasis);
				EndIf;
				
				RunCallback(
					New CallbackDescription(
						"CancelPaymentByCreditCard",
						AdditionalParameters.Form,
						CancellationOptions));
				
			EndIf;
		ElsIf SelectionResult.Action = "CancelPaymentsSequentially" Then
			If SelectionResult.RowSelected.Count() > 0 Then
				
				CancellationOptions = New Structure;
				CancellationOptions.Insert(
					"NotificationOnCompletion",
					New CallbackDescription(
						"CancelPaymentsByPaymentCardsCompletion",
						AdditionalParameters.Form,
						AdditionalParameters));
				CancellationOptions.Insert("PaymentLinesWithPaymentCards", SelectionResult.RowSelected);
				CancellationOptions.Insert("Form",                   AdditionalParameters.Form);
				CancellationOptions.Insert("Currency",                  AdditionalParameters.Currency);
				CancellationOptions.Insert("CashRegisterParameters",       AdditionalParameters.CashRegisterParameters);
				CancellationOptions.Insert("TransactionType",           AdditionalParameters.TransactionType);
				
				CancellationOptions.Insert("Action", SelectionResult.Action);
				
				If AdditionalParameters.Property("DocumentBasis") Then
					CancellationOptions.Insert("DocumentBasis", AdditionalParameters.DocumentBasis);
				EndIf;
				
				RunCallback(
					New CallbackDescription(
						"CancelPaymentByCreditCardsSequentially",
						ThisObject,
						CancellationOptions));
				
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region CustomerDisplay

Procedure AfterCompletingCleaningOfBuyerSDisplay(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		OperationParametersList = PeripheralsCustomerDisplaysServerClient.OperationParametersBuyerSDisplay();
		OperationParametersList.LinesOfText = AdditionalParameters.TextToDisplayBuyer;
		
		PeripheralsCustomerDisplaysServerClient.StartDisplayingInformationOnBuyerSDisplay(
			New CallbackDescription("AfterDisplayingTextOnBuyerSDisplay", ThisObject, AdditionalParameters),
			AdditionalParameters.Form.UUID,
			AdditionalParameters.DeviceID,
			OperationParametersList);
		
	Else
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi sử dụng màn hình khách hàng, đã xảy ra lỗi.
			           |Mô tả bổ sung:
			           |%1';
			           |ru = 'При использовании дисплея покупателя произошла ошибка.
			           |Дополнительное описание:
			           |%1';
			           |en = 'An error occurred while using a customer display.
			           |Additional details:
			           |%1'; fa = 'An error occurred while using a customer display.
			           |Additional details:
			           |%1';
			           |it = 'Si è verificato un errore durante l''utilizzo del display dell''acquirente.
			           |Ulteriore descrizione:
			           |%1';
			           |pl = 'Podczas korzystania z monitora kupującego wystąpił błąd.
			           |Dodatkowy opis:
			           |%1';
			           |tr = 'Müşteri ekranı kullanılırken hata oluştu.
			           |Ek ayrıntılar:
			           |%1'"),
			ExecutionResult.ErrorDescription);
		
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

Procedure AfterDisplayingTextOnBuyerSDisplay(ExecutionResult, AdditionalParameters) Export
	
	If Not ExecutionResult.Result Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi sử dụng màn hình khách hàng, đã xảy ra lỗi.
			           |Mô tả bổ sung:
			           |%1';
			           |ru = 'При использовании дисплея покупателя произошла ошибка.
			           |Дополнительное описание:
			           |%1';
			           |en = 'An error occurred while using a customer display.
			           |Additional details:
			           |%1'; fa = 'An error occurred while using a customer display.
			           |Additional details:
			           |%1';
			           |it = 'Si è verificato un errore durante l''utilizzo del display dell''acquirente.
			           |Ulteriore descrizione:
			           |%1';
			           |pl = 'Podczas korzystania z monitora kupującego wystąpił błąd.
			           |Dodatkowy opis:
			           |%1';
			           |tr = 'Müşteri ekranı kullanılırken hata oluştu.
			           |Ek ayrıntılar:
			           |%1'"),
			ExecutionResult.ErrorDescription);
		
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region RegisterShifts

Procedure AfterExecutingOpenShiftCommand(ExecutionResult, AdditionalParameters) Export
	
	ShiftIsOpenOnDevice = ExecutionResult.Result;
	If Not ShiftIsOpenOnDevice Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi mở phiên làm việc, đã xảy ra lỗi.
			           |Chưa đóng phiên làm việc trên máy ghi nhận tiền mặt.
			           |Mô tả bổ sung:
			           |%1';
			           |ru = 'При открытии смены произошла ошибка.
			           |Смена не открыта на фискальном устройстве.
			           |Дополнительное описание:
			           |%1';
			           |en = 'An error occurred while opening the shift.
			           |The shift is not opened on the fiscal device.
			           |Additional details:
			           |%1'; fa = 'An error occurred while opening the shift.
			           |The shift is not opened on the fiscal device.
			           |Additional details:
			           |%1';
			           |it = 'Si è verificato un errore durante l''apertura del turno.
			           |Il turno non è aperto sul registratore fiscale.
			           |Ulteriore descrizione:
			           |%1';
			           |pl = 'Podczas otwierania zmiany wystąpił błąd.
			           |Zmiana nie jest otwarta na urządzeniu fiskalnym.
			           |Dodatkowy opis:
			           |%1';
			           |tr = 'Vardiya açılırken hata oluştu.
			           |Değişiklik mali cihazda açılmadı.
			           |Ek ayrıntılar:
			           |%1'"),
			ExecutionResult.ErrorDescription);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
	
	If AdditionalParameters.CallbackDescriptionCompletion <> Undefined Then
		RunCallback(AdditionalParameters.CallbackDescriptionCompletion, ShiftIsOpenOnDevice);
	EndIf;
	
EndProcedure

Procedure AfterExecutingShiftCloseCommand(ExecutionResult, Context) Export
	
	RemovedZReportOnDevice = ExecutionResult.Result;
	If RemovedZReportOnDevice Then
		
		OpenReportsTabForChangingFormOfPOSShiftDocument(ExecutionResult.CashRegisterShift);
		TellUserDescriptionOfErrorWhenClosingPOSShift(ExecutionResult.ErrorDescription);
		
		StartExecutionClosingCashShiftAtAcquiringTerminal(ExecutionResult, Context);
		
	Else
		
		QueryText = NStr("vi = 'Đã xảy ra lỗi khi xuất báo cáo trên thiết bị ghi nhận tiền mặt.
		                    |""%ErrorDescription%""
		                    |
		                    |Nếu đóng phiên làm việc trên thiết bị ghi nhận tiền mặt thì
		                    |hãy nhấn ""Có"" để lập bảng kê bán lẻ hàng hóa.
		                    |
		                    |Đóng phiên?';
		                    |ru = 'При снятии отчета на фискальном устройстве произошла ошибка.
		                    |""%ErrorDescription%""
		                    |
		                    |Если смена на фискальном устройстве закрыта, то
		                    |нажмите ""Да"" для формирования отчета о розничных продажах.
		                    |
		                    |Закрыть смену?';
		                    |en = 'An error occurred when receiving the report from the fiscal device.
		                    |""%ErrorDescription%""
		                    |
		                    |If the shift is closed on the fiscal device,
		                    |click Yes to generate a retail sales report.
		                    |
		                    |Close the shift?'; fa = 'An error occurred when receiving the report from the fiscal device.
		                    |""%ErrorDescription%""
		                    |
		                    |If the shift is closed on the fiscal device,
		                    |click Yes to generate a retail sales report.
		                    |
		                    |Close the shift?';
		                    |it = 'Si è verificato un errore durante l''estrazione del report sul dispositivo fiscale.
		                    |""%ErrorDescription%""
		                    |
		                    |Se il turno sul dispositivo fiscale è già chiuso, 
		                    |clicca ""Si"" per generare un report sulle vendite al dettaglio.
		                    |
		                    |Chiudere il turno?';
		                    |pl = 'Podczas otwierania raportu fiskalnego urządzeniu wystąpił błąd.
		                    |""%ErrorDescription%""
		                    |
		                    |Jeśli zmiana na urządzeniu fiskalnym jest zamknięta, 
		                    |naciśnij ""Tak"" dla tworzenia raportu o sprzedaży detalicznej.
		                    |
		                    |Zamknij zmianę?';
		                    |tr = 'Mali cihazda rapor alınırken hata oluştu.
		                    |""%ErrorDescription%""
		                    |
		                    | Mali cihazdaki vardiya kapalıysa, perakende satış raporu
		                    |oluşturmak için ""Evet ""e basın.
		                    |
		                    | Vardiya kapatılsın mı?'");
		QueryText = StrReplace(QueryText, "%ErrorDescription%", ExecutionResult.ErrorDescription);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ErrorDescription",               ExecutionResult.ErrorDescription);
		AdditionalParameters.Insert("CallbackDescriptionCompletion", Context.CallbackDescriptionCompletion);
		AdditionalParameters.Insert("FiscalDevice",         Context.FiscalDevice);
		
		ShowQueryBox(
			New CallbackDescription(
				"AfterAnsweringQuestionAboutForcedFormationOfRetailSalesReport",
				RetailSalesClient,
				AdditionalParameters),
			QueryText,
			QuestionDialogMode.YesNo,,
			DialogReturnCode.No);
		
	EndIf;
	
EndProcedure

Procedure StartExecutionClosingCashShiftAtAcquiringTerminal(ExecutionResult, Context) Export
	
	ConnectedTerminals = RetailSalesServerCall.EquippingAcquiringTerminalForReconciliationOfTotals(Context.FiscalDevice);
	
	CallbackDescription = New CallbackDescription("RunTotalsRevisionCompletion", RetailSalesClient, Context); 
	If ConnectedTerminals.Count() > 0 Then
		For Each Peripherals In ConnectedTerminals Do
			OperationParametersList = PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation();
			PeripheralsPaymentSystemsServerClient.StartReconciliationOfTotalsAtAcquiringTerminal(
				CallbackDescription,
				New UUID,
				Peripherals,
				OperationParametersList);
		EndDo;
	Else
		RunCallback(CallbackDescription, Undefined);
	EndIf;
	
EndProcedure

Procedure RunTotalsRevisionCompletion(ExecutionResult, Context) Export
	
	If ExecutionResult <> Undefined Then     	
		If ExecutionResult.Result Then
			MessageText = NStr("vi = 'Đã thực hiện đối chiếu thành công phần tổng kết giao dịch thẻ';
								|ru = 'Сверка итогов эквайринга выполнена успешно.';
								|en = 'Acquiring totals are reconciled.'; fa = 'Acquiring totals are reconciled.';
								|it = 'Сверка итогов эквайринга выполнена успешно.';
								|pl = 'Acquiring totals are reconciled.';
								|tr = 'PoS bankacılık sonuçlarının mutabakatı başarıyla gerçekleştirilmiştir.'");
		Else
			MessageText = ExecutionResult.ErrorDescription;
		EndIf; 
		CommonClient.MessageToUser(MessageText); 
	EndIf;
	
	If Context.CallbackDescriptionCompletion <> Undefined Then
		RunCallback(Context.CallbackDescriptionCompletion, True);
	EndIf;   
	
EndProcedure

Procedure AfterAnsweringQuestionAboutForcedFormationOfRetailSalesReport(QuestionResult, Context) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		GenerateReportOnRetailSales(Context.FiscalDevice);
		
		If Context.CallbackDescriptionCompletion <> Undefined Then
			RunCallback(Context.CallbackDescriptionCompletion, True);
		EndIf;
		
	Else
		
		MessageText = NStr("vi = 'Đã xảy ra lỗi khi xuất báo cáo trên máy ghi nhận tiền mặt.
		                     |""%ErrorDescription%""
		                     |Chưa lập báo cáo trên thiết bị ghi nhận tiền mặt.';
		                     |ru = 'При снятии отчета на фискальном устройстве произошла ошибка.
		                     |""%ErrorDescription%""
		                     |Отчет на фискальном устройстве не сформирован.';
		                     |en = 'An error occurred when receiving the report from the fiscal device.
		                     |""%ErrorDescription%""
		                     |The report is not generated on the fiscal device.'; fa = 'An error occurred when receiving the report from the fiscal device.
		                     |""%ErrorDescription%""
		                     |The report is not generated on the fiscal device.';
		                     |it = 'Si è verificato un errore durante l''estrazione del report sul dispositivo fiscale.
		                     |""%ErrorDescription%""
		                     |Il report sul dispositivo fiscale non è generato.';
		                     |pl = 'Podczas otwierania raportu fiskalnego urządzeniu wystąpił błąd.
		                     |""%ErrorDescription%""
		                     |Raport na urządzeniu fiskalnym nie generowany.';
		                     |tr = 'Mali cihazla ilgili rapor alınırken hata oluştu.
		                     |""%ErrorDescription%""
		                     | Mali cihazla ilgili rapor oluşturulmadı.'");
		MessageText = StrReplace(MessageText, "%ErrorDescription%", Context.ErrorDescription);
		CommonClient.MessageToUser(MessageText);
		
		If Context.CallbackDescriptionCompletion <> Undefined Then
			RunCallback(Context.CallbackDescriptionCompletion, False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AfterExecutingCommandReportWithoutCancellation(ExecutionResult, Context) Export    
	
	If ExecutionResult <> Undefined Then     	
		If ExecutionResult.Result Then 
			 MessageText = NStr("vi = 'Đã hoàn tất giao dịch thành công.';
								|ru = 'Операция успешно завершена.';
								|en = 'Operation completed successfully.'; fa = 'Operation completed successfully.';
								|it = 'Операция успешно завершена.';
								|pl = 'Operacja została zakończona pomyślnie.';
								|tr = 'İşlem başarıyla tamamlanmıştır.'");
		Else
			MessageText = StrTemplate(
			NStr("vi = 'Không thể tạo Báo cáo tạm thời, đã xảy ra lỗi. 	
			|Mô tả bổ sung:
			|%1';
			|ru = 'Не удалось сформировать Отчет без гашения, произошла ошибка. 	
			|Дополнительное описание:
			|%1';
			|en = 'An error occurred when trying to generate the Report without clearance. 	
			|Additional details:
			|%1'; fa = 'An error occurred when trying to generate the Report without clearance. 	
			|Additional details:
			|%1';
			|it = 'Не удалось сформировать Отчет без гашения, произошла ошибка. 	
			|Дополнительное описание:
			|%1';
			|pl = 'An error occurred when trying to generate the Report without clearance. 	
			|Additional details:
			|%1';
			|tr = 'Sönme olmadan Rapor oluşturulamadı, bir hata gerçekleşti. 	
			|﻿Ek ayrıntılar: 
			|%1'"),
			ExecutionResult.ErrorDescription); 		 		
		EndIf;   
		
		CommonClient.MessageToUser(MessageText);
	EndIf;    
	
	If Context.CallbackDescriptionCompletion <> Undefined Then
		RunCallback(Context.CallbackDescriptionCompletion, True);
	EndIf;   
	
EndProcedure 

#EndRegion

#Region DepositingAndWithdrawingMoney

// Parameters:
// 	WithdrawnAmount - Number
// 	AdditionalParameters - Structure:
//		* CallbackDescriptionCompletion - CallbackDescription
//
Procedure WithdrawalOfMoneyCompletion(WithdrawnAmount, AdditionalParameters) Export
	
	If WithdrawnAmount <> Undefined And TypeOf(WithdrawnAmount) = Type("Number") Then
		
		DetailsWithdrawalOfFundsFromCashDeskOfCashRegister = New Structure;
		DetailsWithdrawalOfFundsFromCashDeskOfCashRegister.Insert("Organization",    AdditionalParameters.CashRegisterParameters.Organization);
		DetailsWithdrawalOfFundsFromCashDeskOfCashRegister.Insert("CashRegister",       AdditionalParameters.CashRegisterParameters.CashRegister);
		DetailsWithdrawalOfFundsFromCashDeskOfCashRegister.Insert("DocumentAmount", WithdrawnAmount);
		DetailsWithdrawalOfFundsFromCashDeskOfCashRegister.Insert("Currency",         AdditionalParameters.CashRegisterParameters.Currency);
		
		//We create a document of the extraction of the cash means of the Cash register, regardless of the Cash Register parameter.Use of connectionsequipment
		LinkToDocumentNotch = Undefined;
		ErrorDescription = "";
		Result = RetailSalesServerCall.CreateDocumentWithdrawalOfFundsFromCashRegisterCashRegister(
			DetailsWithdrawalOfFundsFromCashDeskOfCashRegister, LinkToDocumentNotch, ErrorDescription);
		
		If AdditionalParameters.CallbackDescriptionCompletion <> Undefined
			And AdditionalParameters.CallbackDescriptionCompletion.AdditionalParameters <> Undefined Then
			AdditionalParameters.CallbackDescriptionCompletion.AdditionalParameters.Insert("DocumentReference", LinkToDocumentNotch);
		EndIf;
			
		If Result Then
			
			If Not AdditionalParameters.CashRegisterParameters.UseWithoutConnectingPeripherals Then
				
				OperationParametersList = New Structure;
				OperationParametersList.Insert("DocumentAmount",                  WithdrawnAmount);
				OperationParametersList.Insert("DocumentRef",                  LinkToDocumentNotch);
				OperationParametersList.Insert("Organization",                     AdditionalParameters.CashRegisterParameters.Organization);
				OperationParametersList.Insert("RetailFacility",                  AdditionalParameters.CashRegisterParameters.CashRegister);
				OperationParametersList.Insert("Peripherals_",        AdditionalParameters.CashRegisterParameters.DeviceID);
				
				TMPeripheralsClient.PunchCheckWithdrawalOfFunds(
					AdditionalParameters.Form,
					OperationParametersList,
					Undefined,
					AdditionalParameters.CallbackDescriptionCompletion);
			Else
				
				If AdditionalParameters.CallbackDescriptionCompletion <> Undefined Then
					RunCallback(AdditionalParameters.CallbackDescriptionCompletion, Result);
				EndIf;
					
			EndIf;
			
		Else		
			MessageText = StrTemplate(
				NStr("vi = 'Đã xảy ra lỗi khi rút tiền từ quầy thu ngân.
				           |Mô tả bổ sung:
				           |%1';
				           |ru = 'При выемке денежных средств из кассы ККМ произошла ошибка.
				           |Дополнительное описание:
				           |%1';
				           |en = 'An error occurred during taking cash out of the cash register.
				           |Additional details:
				           |%1'; fa = 'An error occurred during taking cash out of the cash register.
				           |Additional details:
				           |%1';
				           |it = 'Si è verificato un errore durante l''estrazione dei contanti dal registratore di cassa.
				           |Ulteriore descrizione:
				           | %1';
				           |pl = 'Podczas usuwania środków pieniężnych z kasy KF wystąpił błąd.
				           |Dodatkowy opis:
				           |%1';
				           |tr = 'Yazar Kasadan nakit para çekilirken hata oluştu.
				           |Ek ayrıntılar:
				           |%1'"), ErrorDescription);
			CommonClient.MessageToUser(MessageText);
			
			If AdditionalParameters.CallbackDescriptionCompletion <> Undefined Then
				RunCallback(AdditionalParameters.CallbackDescriptionCompletion, Result);
			EndIf;
				
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
// 	StructureSelectedData - Structure
// 	AdditionalParameters - Structure:
//		* CallbackDescriptionCompletion - CallbackDescription
//
Procedure DepositingMoneyCompletion(StructureSelectedData, AdditionalParameters) Export
	Result = False;
	
	If Not StructureSelectedData = Undefined Then
		
		DetailsDepositingFundsToCashDeskOfCashRegister = New Structure;
		DetailsDepositingFundsToCashDeskOfCashRegister.Insert("Organization",       StructureSelectedData.Organization);
		DetailsDepositingFundsToCashDeskOfCashRegister.Insert("CashAccount",             StructureSelectedData.CashAccount);
		DetailsDepositingFundsToCashDeskOfCashRegister.Insert("CashRegister",          StructureSelectedData.CashRegister);
		DetailsDepositingFundsToCashDeskOfCashRegister.Insert("DocumentAmount",    StructureSelectedData.DepositAmount);
		DetailsDepositingFundsToCashDeskOfCashRegister.Insert("Currency",            StructureSelectedData.Currency);
		DetailsDepositingFundsToCashDeskOfCashRegister.Insert("DocumentBasis", StructureSelectedData.CashAccountReceiptNote);
		
		//We create a document for depositing monetary funds in the Cash register, regardless of the Cash Register parameter.Use of connectionsequipment
		LinkToDocumentIntroduction = Undefined;
		ErrorDescription = "";
		Result = RetailSalesServerCall.CreateDocumentDepositingFundsToCashRegister(
			DetailsDepositingFundsToCashDeskOfCashRegister, LinkToDocumentIntroduction, ErrorDescription);
			
		If AdditionalParameters.CallbackDescriptionCompletion <> Undefined Then
			AdditionalParameters.CallbackDescriptionCompletion.AdditionalParameters.Insert("DocumentReference", LinkToDocumentIntroduction);
		EndIf;
		
		If Result Then 
					
			If Not AdditionalParameters.CashRegisterParameters.UseWithoutConnectingPeripherals Then
				
				OperationParametersList = New Structure;
				OperationParametersList.Insert("DocumentAmount",                   StructureSelectedData.DepositAmount);
				OperationParametersList.Insert("Currency",                           StructureSelectedData.Currency);
				OperationParametersList.Insert("DocumentRef",                   LinkToDocumentIntroduction);
				OperationParametersList.Insert("Organization",                      StructureSelectedData.Organization);
				OperationParametersList.Insert("RetailFacility",                   StructureSelectedData.CashRegister);
				OperationParametersList.Insert("Peripherals_",         AdditionalParameters.CashRegisterParameters.DeviceID);
				
				TMPeripheralsClient.PunchReceiptDepositFunds(
					AdditionalParameters.Form,
					OperationParametersList,
					Undefined,
					AdditionalParameters.CallbackDescriptionCompletion);
			Else
				
				If AdditionalParameters.CallbackDescriptionCompletion <> Undefined Then
					RunCallback(AdditionalParameters.CallbackDescriptionCompletion, Result);
				EndIf;
					
			EndIf;
					
		Else
			
			MessageText = StrTemplate(
				NStr("vi = 'Đã xảy ra lỗi khi nhập tiền vào quầy thu ngân.
				           |Mô tả bổ sung:
				           |%1';
				           |ru = 'При внесении денежных средств в кассу ККМ произошла ошибка.
				           |Дополнительное описание:
				           |%1';
				           |en = 'An error occurred while putting cash into the cash register.
				           |Additional details:
				           |%1'; fa = 'An error occurred while putting cash into the cash register.
				           |Additional details:
				           |%1';
				           |it = 'Si è verificato un errore durante il versamento dei contanti al registratore di cassa.
				           |Ulteriore descrizione:
				           | %1';
				           |pl = 'Podczas wprowadzenia środków pieniężnych w kasie KF wystąpił błąd.
				           |Dodatkowy opis:
				           |%1';
				           |tr = 'Yazar Kasaya para yatırılırken hata oluştu.
				           |Ek ayrıntılar:
				           |%1'"),
				ErrorDescription);
			CommonClient.MessageToUser(MessageText);
			
			If AdditionalParameters.CallbackDescriptionCompletion <> Undefined Then
				RunCallback(AdditionalParameters.CallbackDescriptionCompletion, Result);
			EndIf;
			
		EndIf;
		
	EndIf;
		
EndProcedure

#EndRegion

Procedure CloseKmVerificationSessionOnCCTCompletion(Result, AdditionalParameters) Export
	
	// Process, if necessary, the result of closing the KM check session on the CCT.
	Return;
	
EndProcedure

// Updates the Room value in the rows of the table part of the Series, called from the cashier's workplace forms.
// 
// Parameters:
//  Form - ClientApplicationForm - 
//  TheCurrentDataRow - Structure
//  OldRoomValue - CatalogRef
//
Procedure UpdateRoomInRowsOfTabularPartOfSeries(Form, TheCurrentDataRow, OldRoomValue) Export
	
	FormObject1 = Form.Object; // DocumentObject.CashRegisterReceipt, DocumentObject.CashRegisterReceiptReturn
	If Not TheCurrentDataRow = Undefined And Form.SeriesSpecificationParameters.UseItemsBatch And FormObject1.SetOfSeries.Count() Then
		If TheCurrentDataRow.Premise <> OldRoomValue Then
			FilterParameters = New Structure;
			FilterParameters.Insert("Premise", OldRoomValue);
			FilterParameters.Insert("Products", TheCurrentDataRow.Products);
			If Form.UseItemVariants Then
				FilterParameters.Insert("Characteristic", TheCurrentDataRow.Characteristic);
			EndIf;
			SeriesForProcessing = FormObject1.SetOfSeries.FindRows(FilterParameters);
			For Each SeriesString In SeriesForProcessing Do
				SeriesString.Premise = TheCurrentDataRow.Premise;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

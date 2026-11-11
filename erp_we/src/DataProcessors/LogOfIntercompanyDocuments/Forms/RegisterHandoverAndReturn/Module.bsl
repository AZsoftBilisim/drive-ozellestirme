
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("EndingDateOfPeriod") And ValueIsFilled(Parameters.EndingDateOfPeriod) Then
		Period.EndDate = EndOfMonth(Parameters.EndingDateOfPeriod);
	ElsIf Parameters.Property("RegistrationPeriod") And ValueIsFilled(Parameters.RegistrationPeriod) Then
		Period.EndDate = EndOfMonth(Parameters.RegistrationPeriod);
	EndIf;
	
	If Parameters.Property("Organization") And ValueIsFilled(Parameters.Organization) Then
		Recipient  = Parameters.Organization;
		Sender = Parameters.Organization;
	EndIf;
	
	ToRegisterForAPeriod.Parameters.SetParameterValue("Recipient",  Recipient);
	ToRegisterForAPeriod.Parameters.SetParameterValue("Sender", Sender);
	
	SetParametersForDynamicLists();
	FormItemsManagement();
	
	Items.ToRegisterForAPeriodWarehouse.Visible = GetFunctionalOption("UseSeveralWarehouses");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If (EventName = "Write_CustomerInvoiceIntercompany"
		Or EventName = "Write_IntercompanyGoodsReturn") Then
		
		FormItemsManagement();
		Items.ToRegister.Refresh();
		Items.ToRegisterForAPeriod.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	
	SetParametersForDynamicLists();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure RegistrationOptionOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure LabelStartProcessingClick(Item)
	
	ClearMessages();
	
	BackgroundJobRun();
	InterfaceChangesWhenRunningBackgroundJob();
	
	HandlerParameters = New Structure("Interval", 1);
	AttachIdleHandler("BackgroundJobCheckOnClient", HandlerParameters.Interval, True);
	
EndProcedure

&AtClient
Procedure CancelJob(Command)
	
	DetachIdleHandler("BackgroundJobCheckOnClient");
	InterfaceChangesWhenRunningBackgroundJob(True);
	CancelBackgroundJob();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateDocument(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessors.LogOfIntercompanyDocuments.RegisterHandoverAndReturn.Command.CreateDocument");
	
	String = Items.ToRegister.CurrentData;
	
	If String <> Undefined Then
		
		StructureBase = New Structure;
		StructureBase.Insert("Organization",				String.Sender);
		StructureBase.Insert("CompanyRecipient",	String.Recipient);
		StructureBase.Insert("Warehouse",					String.Warehouse);
		StructureBase.Insert("TransferForActivity_",	String.TransferForActivity_);
		StructureBase.Insert("InventoryType",				String.InventoryType);
		StructureBase.Insert("BeginOfPeriod",			String.RegistrationDate);
		StructureBase.Insert("EndOfPeriod",				String.LastSaleDate);
		StructureBase.Insert("BusinessOperation",	String.BusinessOperation);
		StructureBase.Insert("RegistrationDate",			String.RegistrationDate);
		StructureBase.Insert("Contract",					String.Contract);
		StructureBase.Insert("PriceKind",					String.PriceKind);
		StructureBase.Insert("ARAPCurrency",		String.ARAPCurrency);
		StructureBase.Insert("ThisIsTransferReturn21",			True);
		
		OpeningParameters = New Structure("Basis", StructureBase);
		
		If String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany")
			Or String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsSaleToAnotherCompany") Then
			OpenForm("Document.CustomerInvoiceIntercompany.ObjectForm", OpeningParameters, Items.ToRegisterForAPeriod);
		Else
			OpenForm("Document.IntercompanyGoodsReturn.ObjectForm", OpeningParameters, Items.ToRegisterForAPeriod);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateADocumentForAPeriod(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessors.LogOfIntercompanyDocuments.RegisterHandoverAndReturn.Command.CreateADocumentForAPeriod");
	
	String = Items.ToRegisterForAPeriod.CurrentData;
	
	If String <> Undefined Then
		
		StructureBase = New Structure;
		StructureBase.Insert("Organization",				String.Sender);
		StructureBase.Insert("CompanyRecipient",	String.Recipient);
		StructureBase.Insert("Warehouse",					String.Warehouse);
		StructureBase.Insert("TransferForActivity_",	String.TransferForActivity_);
		StructureBase.Insert("InventoryType",				String.InventoryType);
		StructureBase.Insert("BeginOfPeriod",			?(ValueIsFilled(String.Month), BegOfMonth(String.Month), Period.StartDate));
		StructureBase.Insert("EndOfPeriod",				?(ValueIsFilled(String.Month), EndOfMonth(String.Month), Period.EndDate));
		StructureBase.Insert("BusinessOperation",	String.BusinessOperation);
		StructureBase.Insert("RegistrationDate",			Undefined);
		StructureBase.Insert("Contract",					String.Contract);
		StructureBase.Insert("PriceKind",					String.PriceKind);
		StructureBase.Insert("ARAPCurrency",		String.ARAPCurrency);
		StructureBase.Insert("ThisIsTransferReturn21",		True);
		
		ParametersStructure1 = New Structure("Basis", StructureBase);
		
		If String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany")
			Or String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsSaleToAnotherCompany") Then
			OpenForm("Document.CustomerInvoiceIntercompany.ObjectForm", ParametersStructure1, Items.ToRegisterForAPeriod);
		Else
			OpenForm("Document.IntercompanyGoodsReturn.ObjectForm", ParametersStructure1, Items.ToRegisterForAPeriod);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateForRegistration(Command)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CorrectBalanceInThisSession(Command)
	
	FixLeftoversInThisSessionOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersToRegister

&AtClient
Procedure ToRegisterBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersToRegisterForAPeriod

&AtClient
Procedure ToRegisterForAPeriodBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FormItemsManagement()
	
	If RegistrationOption = 1 Then
		RequirementsForRegistration();
		Items.GroupToRegister.CurrentPage = Items.PageByDays;
	Else
		SetParametersForDynamicLists();
		Items.GroupToRegister.CurrentPage = Items.PageForThePeriod;
	EndIf;
	
	If ThereAreNegativeBalancesAtEndOfPeriod() Then
		Items.GroupCorrectionOfNegativeBalances.Visible = True;
		Items.CorrectBalanceInThisSession.Visible = CommonClientServer.DebugMode();
		Items.GroupCorrectionOfNegativeBalances.CurrentPage = Items.GroupNegativeBalances;
		Items.ToRegisterCreateDocument.Enabled = False;
		Items.ToCreateADocumentForAPeriod.Enabled = False;
	Else
		Items.GroupCorrectionOfNegativeBalances.Visible = False;
		Items.ToRegisterCreateDocument.Enabled = True;
		Items.ToCreateADocumentForAPeriod.Enabled = True;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetParametersForDynamicLists()
	
	BeginOfPeriod	= BegOfDay(?(ValueIsFilled(Period.StartDate), Period.StartDate, '00010101'));
	EndOfPeriod	= EndOfDay(?(ValueIsFilled(Period.EndDate), Period.EndDate, '39991231'));
	
	If BeginOfPeriod > EndOfPeriod Then
		Raise NStr("vi = 'Ngày bắt đầu Kỳ không thể dài hơn ngày kết thúc';
					|ru = 'Дата начала периода не может быть больше даты окончания периода';
					|en = 'The period start date cannot be greater than the period end date'; fa = 'The period start date cannot be greater than the period end date';
					|it = 'La data di inizio periodo non può essere superiore alla data del termine periodo';
					|pl = 'Data rozpoczęcia okresu nie może być dłuższa niż data zakończenia okresu';
					|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz'");
	EndIf;
	
	ToRegisterForAPeriod.Parameters.SetParameterValue("BeginOfPeriod", BeginOfPeriod);
	ToRegisterForAPeriod.Parameters.SetParameterValue("EndOfPeriod", EndOfPeriod);
	
EndProcedure

&AtServer
Procedure RequirementsForRegistration()
	Query = New Query("
		|SELECT
		|	Consumption_1.RegistrationDate,
		|	Consumption_1.Sender,
		|	Consumption_1.Recipient,
		|	Consumption_1.ItemsLocationAttributes, 
		|	Consumption_1.Warehouse,
		|	Consumption_1.Period,
		|	Consumption_1.InventoryOwnerAttribute,
		|	Consumption_1.RecipientInventoryOwnerAttribute,
		|	Consumption_1.InventoryType,
		|	Consumption_1.VATTaxation,
		|	Consumption_1.CCDNumber,
		|	Consumption_1.Consumed
		|INTO Consumption_1
		|FROM &GoodsToTransfer AS Consumption_1
		|;
		|
		|SELECT
		|	(CASE Consumption_1.InventoryType
		|		WHEN VALUE(Enum.InventoryTypes.ConsignedGoods)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
		|		ELSE VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany) END) AS BusinessOperation,
		|	Consumption_1.RegistrationDate,
		|	Consumption_1.Sender,
		|	Consumption_1.Recipient,
		|	Consumption_1.Warehouse,
		|	Consumption_1.InventoryType,
		|	Consumption_1.VATTaxation AS TransferForActivity_,
		|	MAX(Consumption_1.Period) AS LastSaleDate,
		|	COUNT(1) AS GoodsLines,
		|	1 AS Order,
		|	DefaultValues.Contract AS Contract,
		|	DefaultValues.PriceKind AS PriceKind,
		|	DefaultValues.Currency AS ARAPCurrency
		|FROM
		|	Consumption_1 AS Consumption_1
		|
		|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON InventoryKinds.Ref = Consumption_1.InventoryOwnerAttribute
		|
		|	INNER JOIN
		|		InformationRegister.CustomizeCustomerInvoiceIntercompany AS DefaultValues
		|	ON
		|		Consumption_1.Sender = DefaultValues.CompanyOwner
		|		AND InventoryKinds.InventoryType = DefaultValues.InventoryType
		|		AND Consumption_1.Recipient = DefaultValues.CompanyCustomer
		|WHERE
		|	&Sender IN (VALUE(Catalog.Companies.EmptyRef), Consumption_1.Sender)
		|	OR &Recipient IN (VALUE(Catalog.Companies.EmptyRef), Consumption_1.Recipient)
		|
		|GROUP BY
		|	Consumption_1.RegistrationDate, 
		|	Consumption_1.Sender, 
		|	Consumption_1.Recipient,
		|	Consumption_1.Warehouse,
		|	Consumption_1.InventoryType, 
		|	Consumption_1.VATTaxation,
		|	DefaultValues.Contract,
		|	DefaultValues.PriceKind,
		|	DefaultValues.Currency
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	(CASE InventoryKinds.InventoryType
		|		WHEN VALUE(Enum.InventoryTypes.ConsignedGoods)
		|			THEN VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
		|		ELSE VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn) END) AS BusinessOperation,
		|	DATETIME(1,1,1) AS RegistrationDate,
		|	InventoryKinds.Organization AS Sender,
		|	OnDate.CompanyOwner AS Recipient,
		|	OnDate.ItemsLocationAttributes.StorageLocation AS Warehouse,
		|	InventoryKinds.InventoryType AS InventoryType,
		|	InventoryKinds.VATTaxation AS TransferForActivity_,
		|	DATETIME(1,1,1) AS LastSaleDate,
		|	0 AS GoodsLines,
		|	2 AS Order,
		|	DefaultValues.Contract AS Contract,
		|	DefaultValues.PriceKind AS PriceKind,
		|	DefaultValues.Currency AS ARAPCurrency
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer.Balance(&PeriodBoundary) AS OnDate
		|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON InventoryKinds.Ref = OnDate.SellerInventoryOwnerAttribute
		|	LEFT JOIN AccumulationRegister.CompanyGoodsForTransfer.Balance() AS ForNow
		|		ON OnDate.ItemsLocationAttributes = ForNow.ItemsLocationAttributes
		|		AND OnDate.CCDNumber = ForNow.CCDNumber
		|		AND OnDate.SellerInventoryOwnerAttribute = ForNow.SellerInventoryOwnerAttribute
		|		AND OnDate.CompanyOwner = ForNow.CompanyOwner
		|	INNER JOIN
		|		InformationRegister.CustomizeCustomerInvoiceIntercompany AS DefaultValues
		|	ON
		|		OnDate.CompanyOwner = DefaultValues.CompanyOwner
		|		AND InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = DefaultValues.InventoryType
		|		AND InventoryKinds.Organization = DefaultValues.CompanyCustomer
		|WHERE
		|	ISNULL(ForNow.ReturnedBalance, 0) <> 0
		|
		|ORDER BY
		|	Order, RegistrationDate
		|");
		
	Filters = AccumulationRegisters.CompanyGoodsForTransfer.SelectionOfGoodsForTransfer();
	Filters.BeginOfPeriod = BegOfDay(Period.StartDate);
	Filters.EndOfPeriod = EndOfDay(?(ValueIsFilled(Period.EndDate), Period.EndDate, '39991231'));
	
	If Filters.BeginOfPeriod > Filters.EndOfPeriod Then
		Raise NStr("vi = 'Ngày bắt đầu kỳ cần trước ngày kết thúc kỳ';
					|ru = 'Дата начала периода должна быть меньше даты окончания периода';
					|en = 'Period start date must be less than the period end date'; fa = 'Period start date must be less than the period end date';
					|it = 'La data di inizio periodo deve essere inferiore alla data del termine periodo';
					|pl = 'Data początku okresu powinna być mniejsza od daty zakończenia okresu';
					|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden küçük olmalıdır'");
	EndIf;
	
	Query.SetParameter("Recipient", Recipient);
	Query.SetParameter("Sender", Sender);
	Query.SetParameter("BeginOfPeriod", Filters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Filters.EndOfPeriod);
	Query.SetParameter("PeriodBoundary", New Boundary(Filters.EndOfPeriod, BoundaryType.Including));
	Query.SetParameter("GoodsToTransfer", AccumulationRegisters.CompanyGoodsForTransfer.GoodsToTransfer(Filters));
	
	Result = Query.Execute();
	ToRegister.Load(Result.Unload());
EndProcedure

&AtServer
Function ThereAreNegativeBalancesAtEndOfPeriod()
	
	Query = New Query(
	"SELECT TOP 1
	|	BalancesAtEndOfPeriod.CompanyOwner AS CompanyOwner,
	|	BalancesAtEndOfPeriod.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalancesAtEndOfPeriod.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	BalancesAtEndOfPeriod.CCDNumber AS CCDNumber
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.Balance(&AsOfThePeriodEnd, ) AS BalancesAtEndOfPeriod
	|WHERE
	|	BalancesAtEndOfPeriod.CountBalance < 0
	|	OR BalancesAtEndOfPeriod.ReturnedBalance < 0
	|");
	
	EndOfPeriod = EndOfDay(?(ValueIsFilled(Period.EndDate), Period.EndDate, '39991231'));
	Query.SetParameter("AsOfThePeriodEnd", New Boundary(EndOfPeriod, BoundaryType.Including));
	Result = Query.Execute();
	
	ThereAreNegativeBalancesAtEndOfPeriod = Not Result.IsEmpty();
	Return ThereAreNegativeBalancesAtEndOfPeriod;
	
EndFunction

&AtServer
Function BackgroundJobRun()
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	
	If ValueIsFilled(Sender) Then
		Companies = New Array;
		Companies.Add(Sender);
	Else
		Companies = Undefined;
	EndIf;
	
	BeginOfPeriod = BegOfDay(?(ValueIsFilled(Period.StartDate), Period.StartDate, '00010101'));
	EndOfPeriod  = EndOfDay(?(ValueIsFilled(Period.EndDate), Period.EndDate, '39991231'));
	
	JobParameters = New Structure();
	JobParameters.Insert("BeginOfPeriod",  BeginOfPeriod);
	JobParameters.Insert("EndOfPeriod",   EndOfPeriod);
	JobParameters.Insert("Companies",    Companies);
	JobParameters.Insert("StorageAddress", StorageAddress);
	
	JobID = InventoriesServer.FixBalancesOnItemsToBeTransferredInBackgroundTask(JobParameters);
	
EndFunction

&AtClient
Procedure BackgroundJobCheckOnClient()
	If Not BackgroundJobCompleted() Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Interval", 1);
		AttachIdleHandler("BackgroundJobCheckOnClient", HandlerParameters.Interval, True);
	EndIf;
EndProcedure

&AtClient
Function BackgroundJobCompleted()
	JobCompleted = False;

	Result = GeneralPurposeTMServerCall.CheckBackgroundTask(JobID);
	If Result.CompletedSuccessfully1 Then
		JobCompleted = True;
		PatchResult = GetFromTempStorage(StorageAddress);
		If ValueIsFilled(PatchResult) Then
			For Each ResultString1 In PatchResult Do
				MessageText = "Document "+ ResultString1.Key + " : " + ResultString1.Value;
				CommonClientServer.MessageToUser(MessageText, ResultString1.Key);
			EndDo;
		EndIf;
		InterfaceChangesWhenRunningBackgroundJob(JobCompleted);
		FormItemsManagement();
	ElsIf Result.StillRunning Then
		HandlerParameters = New Structure("Interval", 1);
		AttachIdleHandler("BackgroundJobCheckOnClient", HandlerParameters.Interval, True);
	ElsIf Result.DoneWithErrors Then
		DetachIdleHandler("BackgroundJobCheckOnClient");
		JobCompleted = True;
		InterfaceChangesWhenRunningBackgroundJob(JobCompleted);
		FormItemsManagement();
		
		MessageText = NStr("vi = 'Đã xảy ra lỗi trong khi chạy nhiệm vụ nền. Xem nhật ký sự kiện để biết chi tiết.';
							|ru = 'Возникла ошибка при работе фонового задания. Подробности см. в журнале регистрации.';
							|en = 'An error occurred during background job operation. For more information, see the event log.'; fa = 'An error occurred during background job operation. For more information, see the event log.';
							|it = 'Si è verificato un errore durante l''esecuzione del processo in background. Vedere il registro per i dettagli.';
							|pl = 'Wystąpił błąd podczas pracy w zadania tle. Szczegóły można znaleźć w dzienniku rejestracji.';
							|tr = 'Bir arka plan işi çalıştırılırken hata oluştu. Ayrıntılar için kayıt defterine bak'");
		Raise MessageText;
	EndIf;
	
	Return JobCompleted;
EndFunction

&AtClient
Procedure InterfaceChangesWhenRunningBackgroundJob(JobCompleted = False)
	
	Items.GroupToRegister.Enabled = JobCompleted;
	Items.CustomSettingsFolder.Enabled = JobCompleted;
	Items.PeriodGroup.Enabled = JobCompleted;
	
	If JobCompleted Then
		Items.GroupCorrectionOfNegativeBalances.CurrentPage = Items.GroupNegativeBalances;
	Else
		Items.GroupCorrectionOfNegativeBalances.CurrentPage = Items.GroupLongTermOperations;
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob()
	
	GeneralPurposeTMServerCall.CancelJobExecution(JobID);
	
EndProcedure

&AtServer
Procedure FixLeftoversInThisSessionOnServer()
	
	If ValueIsFilled(Sender) Then
		Companies = New Array;
		Companies.Add(Sender);
	Else
		Companies = Undefined;
	EndIf;
	
	BeginOfPeriod = BegOfDay(?(ValueIsFilled(Period.StartDate), Period.StartDate, '00010101'));
	EndOfPeriod  = EndOfDay(?(ValueIsFilled(Period.EndDate), Period.EndDate, '39991231'));
	
	CallParameters = New Structure();
	CallParameters.Insert("BeginOfPeriod",  BeginOfPeriod);
	CallParameters.Insert("EndOfPeriod",   EndOfPeriod);
	CallParameters.Insert("Companies",    Companies);
	
	InventoriesServer.CorrectBalancesOnGoodsToBeTransferred(CallParameters);
	FormItemsManagement();
	
EndProcedure

#EndRegion

#Region Variables

&AtClient
Var ResponseBeforeWrite;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.DocumentBasis) And Not ValueIsFilled(Object.Ref) Then
		Raise NStr("vi = 'Chỉ có thể nhập chứng từ trên cơ sở chứng từ khác hoặc hợp đồng với khách hàng.';
					|ru = 'Документ можно вводить только на основании другого документа или договора с клиентом.';
					|en = 'You can enter the document only based on another document or a contract with a customer.'; fa = 'You can enter the document only based on another document or a contract with a customer.';
					|it = 'È possibile inserire il documento solo in base a un altro documento o a un accordo con il cliente.';
					|pl = 'Dokument można wprowadzać tylko na podstawie innego dokumentu lub umowy z klientem.';
					|tr = 'Bir belge yalnızca başka bir belge veya istemci ile yapılan bir sözleşme temelinde girilebilir.'");
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	CashServer.ExcludeUnavailableFormsOfPayment(Items.PaymentMethod);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		If Parameters.Property("Basis") Then
			Basis = Parameters.Basis;
		EndIf;
		
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "DocumentBasis", "Visible", ValueIsFilled(Object.DocumentBasis));
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		ReferencesArrray = New Array;
		ReferencesArrray.Add(Object.Ref);
		
		Cancel = True;
		SelfServiceClient.PrintInvoiceForPayment(ReferencesArrray);
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		FinancesClient.CheckDocumentCompletionBasedOn(
			Object,
			Basis);
	EndIf;
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		AmountOfPaymentStages = Object.PaymentScheduleSteps.Total("PaymentAmount");
		
		If Object.DocumentAmount = 0 Then
			
			Object.DocumentAmount = AmountOfPaymentStages;
			
		ElsIf Not ResponseBeforeWrite And Object.DocumentAmount <> AmountOfPaymentStages Then
			Cancel = True;
			QueryText = NStr("vi = 'Số tiền của các giai đoạn trong biên thanh toán không trùng với số tiền trong chứng từ. Điều chỉnh lại số tiền trong các giai đoạn thanh toán?';
							|ru = 'Сумма этапов графика оплаты не совпадает с суммой документа. Скорректировать сумму этапов оплаты?';
							|en = 'Amount of payment milestones is not corresponding to the document amount. Adjust payment milestones amount?'; fa = 'Amount of payment milestones is not corresponding to the document amount. Adjust payment milestones amount?';
							|it = 'Importo delle fasi nel grafico di pagamento non coincide con l''importo nel documento. Correggere l''importo delle fasi di pagamento?';
							|pl = 'Wartość etapów harmonogramu płatności nie pokrywa się z kwotą dokumentu. Skorygować kwotę etapów harmonogramu płatności?';
							|tr = 'Ödeme planının aşamalarının toplamı, belgenin toplamı ile uyuşmuyor. Ödeme aşamalarının tutarı ayarlansın mı?'");
			ShowQueryBox(New CallbackDescription("BeforeWriteCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWriteCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.Yes Then
		ResponseBeforeWrite = True;
		PaymentStepsClientServer.DistributeAmountByStagesOfPaymentSchedule(Object.PaymentScheduleSteps, Object.DocumentAmount);
		Write();
	EndIf;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.ProcessingSBPNotification(ThisObject, Object.Ref, EventName);

EndProcedure

&AtClient
Procedure RefillPurposeOfPayment(Command)
	PopulatePurposeOfPayment();
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
		

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PaymentMethodOnChange(Item)

	WhenChangingPaymentFormServer();
	
EndProcedure

&AtClient
Procedure PartialPaymentOnChange(Item)
	
	If Not Object.PartialPayment And ValueIsFilled(Object.DocumentBasis) Then
		If Object.PaymentScheduleSteps.Count() > 0 Then
			UserAnswer = Undefined;

			ShowQueryBox(New CallbackDescription("PartialPaymentOnChangeCompletion", ThisObject), NStr("vi = 'Bảng giai đoạn thanh toán sẽ được điền theo cơ sở. Tiếp tục?';
																										|ru = 'Таблица этапов оплаты будет заполнена по основанию. Продолжить?';
																										|en = 'Payment milestone table will be filled in by basis. Continue?'; fa = 'Payment milestone table will be filled in by basis. Continue?';
																										|it = 'Tabella delle fasi di pagamento sarà compilata in base a. Continuare?';
																										|pl = 'Tabela etapów płatności zostanie wypełniona wg podstawy. Kontynuować?';
																										|tr = 'Ödeme aşamaları tablosu gerekçesine göre doldurulacaktır. Devam et?'"), QuestionDialogMode.YesNo);
            Return;
		EndIf;
		FillInPaymentStagesBasedOnServer();

	Else
		SetAvailabilityOfItemsForPartialPayment();
	EndIf;
	
EndProcedure

&AtClient
Procedure PartialPaymentOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    If UserAnswer = DialogReturnCode.No Then
        Object.PartialPayment = True;
        Return;
    EndIf;
    
    FillInPaymentStagesBasedOnServer();

EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	PaymentStepsClientServer.DistributeAmountByStagesOfPaymentSchedule(Object.PaymentScheduleSteps, Object.DocumentAmount);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure


&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure InscriptionPaymentSBPURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	StandardProcessing = False;
	ThisIsJustPreview = FormattedStringURL = "DetailsOfOutgoingLink";
	
	If Not Object.Posted
		And Not ThisIsJustPreview Then
		CommonClient.MessageToUser(NStr("vi = 'Để thanh toán qua hệ thống thanh toán nhanh, cần kết chuyển chứng từ.';
										|ru = 'Для оплаты через СБП необходимо провести документ.';
										|en = 'To pay via Faster Payments System, post the document.'; fa = 'To pay via Faster Payments System, post the document.';
										|it = 'To pay via Faster Payments System, post the document.';
										|pl = 'To pay via Faster Payments System, post the document.';
										|tr = 'SBP aracılığıyla ödeme yapmak için belgenin kaydedilmesi gerekmektedir.'"));
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref)
		And Modified
		And Not ThisIsJustPreview Then
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi và sẽ được ghi lại. Tiếp tục?';
						|ru = 'Данные изменены и будут записаны. Продолжить?';
						|en = 'The data has been changed and will be saved. Continue?'; fa = 'The data has been changed and will be saved. Continue?';
						|it = 'The data has been changed and will be saved. Continue?';
						|pl = 'The data has been changed and will be saved. Continue?';
						|tr = 'Veriler değiştirildi ve kaydedildi. Devam edilsin mi?'");
	Else
		
		CashClientLocalization.ProcessingOfNavigationLinkSBP(
			ThisObject, Object.Ref, FormattedStringURL);
		Return;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("URL", FormattedStringURL);
	
	EndNotifications = New CallbackDescription(
		"InscriptionPaymentSBPURLProcessingCompletion",
		ThisObject,
		AdditionalParameters);
	Buttons = QuestionDialogMode.YesNo;
	ShowQueryBox(EndNotifications, QueryText, Buttons);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentScheduleSteps

&AtClient
Procedure PaymentScheduleStepsAfterDeleteRow(Item)
	
	CalculateTotalsOfInvoiceForPaymentToClient(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfInvoiceForPaymentToClient(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentPercentageOnChange(Item)
	
	PaymentStepsClient.PaymentScheduleStepsPaymentPercentageOnChange(Items.PaymentScheduleSteps.CurrentData, Object.PaymentScheduleSteps, Object.DocumentAmount);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentAmountOnChange(Item)

	PaymentStepsClient.PaymentScheduleStepsPaymentAmountOnChange(Items.PaymentScheduleSteps.CurrentData, Object.PaymentScheduleSteps, Object.DocumentAmount);
	Object.DocumentAmount = Object.PaymentScheduleSteps.Total("PaymentAmount");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure SetupSubscriptionToNotifications(Command)
	
	TypesOfEvents = New Array();
	TypesOfEvents.Add(PredefinedValue("Enum.NotificationEventTypes.AccountStatement"));
	TypesOfEvents.Add(PredefinedValue("Enum.NotificationEventTypes.CommercialInvoiceCancellation"));
	TypesOfEvents.Add(PredefinedValue("Enum.NotificationEventTypes.ChangeOfAccount"));
	
	MailoutsAndNotificationsToCustomersClient.SubscribeToAlertsFromPlace(
		Object.Partner,
		TypesOfEvents);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleSteps.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsLineNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PartialPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.DateIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.ThisIsDepositForPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<ký cược bao bì>';
													|ru = '<залог за тару>';
													|en = '<packaging deposit>'; fa = '<packaging deposit>';
													|it = '<cauzione per l''imballaggio>';
													|pl = '<zastaw za tarę>';
													|tr = '<depozito>'"));
	Item.Appearance.SetParameterValue("Enabled", False);

EndProcedure

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	FormItemsManagement();
	SetAvailabilityOfItemsForPartialPayment();
	CalculateTotalsOfInvoiceForPaymentToClient(ThisForm);
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	Items.PartialPayment.Visible = TypeOf(Object.DocumentBasis) <> Type("CatalogRef.CounterpartyContracts");
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	TypesOfEvents = New Array();
	TypesOfEvents.Add(Enums.NotificationEventTypes.AccountStatement);
	TypesOfEvents.Add(Enums.NotificationEventTypes.CommercialInvoiceCancellation);
	TypesOfEvents.Add(Enums.NotificationEventTypes.ChangeOfAccount);
	
	MailoutsAndNotificationsToCustomers.SetVisibilityOfSubscribingToAlertsInObject(
		Items.GroupSubscribeToAlerts,
		Object.Partner,
		TypesOfEvents);
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalsOfInvoiceForPaymentToClient(Form)
	
	TotalPaymentPercentage = 0;
	PreviousDateValue = Date(1, 1, 1);
	Form.LineNumberOfFullPayment = 0;
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		TotalPaymentPercentage = TotalPaymentPercentage + CurRow.PaymentPercentage;
		CurRow.PercentageIsFilledInIncorrectly = (TotalPaymentPercentage > 100);
		CurRow.DateIsFilledInIncorrectly = (PreviousDateValue > CurRow.PaymentDate);
		PreviousDateValue = CurRow.PaymentDate;
		If TotalPaymentPercentage = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	AnyPayment      = Not ValueIsFilled(Object.PaymentMethod);
	CheckoutAvailability = AnyPayment Or (Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_);
	AccountItemAvailability = AnyPayment 
						Or (Object.PaymentMethod = Enums.PaymentForms.BankAccountPayment)
						Or (Object.PaymentMethod = Enums.PaymentForms.InstantPayments);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashAccount", "Enabled", CheckoutAvailability);
	TMCommonUseClientServer.SetFormItemProperty(Items, "BankAccount", "Enabled", AccountItemAvailability);
	
	CustomerCommercialInvoiceLocalization.SetAvailabilityOfItemsByPaymentForm(
		Items.LocalizationGroupPaymentLinkSBP, Object.Ref, Object.PaymentMethod);
	
	SetPrivilegedMode(True);
	If TypeOf(Object.DocumentBasis) = Type("CatalogRef.CounterpartyContracts")
	 Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5")
	 Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5")
	 Then
		Terms = Undefined;
	Else
		Terms = Common.ObjectAttributeValue(Object.DocumentBasis, "Terms");
	EndIf;
	
	If TypeOf(Terms) = Type("CatalogRef.TermsOfSale")
		And Not GetFunctionalOption("ToUseTermsOfSales") Then
		ContractsAreUsed = GetFunctionalOption("UseCustomerContracts");
	Else
		ContractsAreUsed =
			ValueIsFilled(Terms)
			And TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed");
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", "Visible", ContractsAreUsed);
	
	CustomerCommercialInvoiceLocalization.SetSBPPaymentLabel(Object.Ref, ThisObject.InscriptionPaymentSBP);
	
EndProcedure

&AtServer
Procedure WhenChangingPaymentFormServer()
	
	FormItemsManagement();
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsForPartialPayment()
	
	ItemArray = New Array();
	
	ItemArray.Add("PaymentScheduleSteps");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not Object.PartialPayment);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DocumentAmount", "ReadOnly", Not Object.PartialPayment);
	
EndProcedure

&AtServer
Procedure FillInPaymentStagesBasedOnServer()
	
	SetPrivilegedMode(True);
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.SalesOrder") Then
		
		QueryText = "
			|SELECT
			|	1 AS Order,
			|	PaymentSteps.PaymentDate AS PaymentDate,
			|	PaymentSteps.PaymentPercentage AS PaymentPercentage,
			|	PaymentSteps.PaymentAmount AS PaymentAmount,
			|	FALSE AS ThisIsDepositForPackage
			|FROM
			|	Document.SalesOrder.PaymentScheduleSteps AS PaymentSteps
			|WHERE
			|	PaymentSteps.Ref = &Ref
			|	AND PaymentSteps.PaymentAmount <> 0
			|
			|UNION ALL
			|
			|SELECT
			|	2 AS Order,
			|	PaymentSteps.PaymentDate AS PaymentDate,
			|	PaymentSteps.PackageDepositPercentage AS PaymentPercentage,
			|	PaymentSteps.PackageDepositValue AS PaymentAmount,
			|	TRUE AS ThisIsDepositForPackage
			|FROM
			|	Document.SalesOrder.PaymentScheduleSteps AS PaymentSteps
			|WHERE
			|	PaymentSteps.Ref = &Ref
			|	AND PaymentSteps.Ref.PackageDepositIsRequired
			|	AND PaymentSteps.PackageDepositValue <> 0
			|
			|ORDER BY
			|	PaymentDate,
			|	Order
			|";
			
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		QueryText = "
			|SELECT
			|	1 AS Order,
			|	PaymentSteps.PaymentDate AS PaymentDate,
			|	PaymentSteps.PaymentPercentage AS PaymentPercentage,
			|	PaymentSteps.PaymentAmount AS PaymentAmount,
			|	FALSE AS ThisIsDepositForPackage
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS PaymentSteps
			|WHERE
			|	PaymentSteps.Ref = &Ref
			|
			|UNION ALL
			|
			|SELECT
			|	2 AS Order,
			|	PaymentSteps.PaymentDate AS PaymentDate,
			|	PaymentSteps.PackageDepositPercentage AS PaymentPercentage,
			|	PaymentSteps.PackageDepositValue AS PaymentAmount,
			|	TRUE AS ThisIsDepositForPackage
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS PaymentSteps
			|WHERE
			|	PaymentSteps.Ref = &Ref
			|
			|ORDER BY
			|	PaymentDate,
			|	Order
			|";
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		
		QueryText = "
			|SELECT
			|	PaymentScheduleSteps.Ref AS Ref,
			|	PaymentScheduleSteps.LineNumber AS LineNumber,
			|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
			|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
			|	PaymentScheduleSteps.PackageDepositValue AS PaymentAmount,
			|	TRUE AS ThisIsDepositForPackage
			|FROM
			|	Document.CustomerInvoice.PaymentScheduleSteps AS PaymentScheduleSteps
			|WHERE
			|	PaymentScheduleSteps.Ref = &Ref
			|	AND PaymentScheduleSteps.PackageDepositValue > 0
			|
			|UNION ALL
			|
			|SELECT
			|	PaymentScheduleSteps.Ref AS Ref,
			|	PaymentScheduleSteps.LineNumber AS LineNumber,
			|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
			|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
			|	PaymentScheduleSteps.PaymentAmount AS PaymentAmount,
			|	FALSE AS ThisIsDepositForPackage
			|FROM
			|	Document.CustomerInvoice.PaymentScheduleSteps AS PaymentScheduleSteps
			|WHERE
			|	PaymentScheduleSteps.Ref = &Ref
			|	AND PaymentScheduleSteps.PaymentAmount > 0
			|
			|ORDER BY
			|	Ref,
			|	LineNumber
			|";
			
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor") Then
			
		QueryText = "
			|SELECT
			|	DocumentSales.PaymentDate         AS PaymentDate,
			|	100                                 AS PaymentPercentage,
			|	DocumentSales.CommissionAmount AS PaymentAmount
			|FROM
			|	Document.ConsignmentReportToVendor AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
			
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			
		QueryText = "
			|SELECT
			|	DocumentSales.PaymentDate    AS PaymentDate,
			|	100                            AS PaymentPercentage,
			|	DocumentSales.DocumentAmount AS PaymentAmount
			|FROM
			|	Document.ConsignmentReportFromCustomer AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
			
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
			
		QueryText = "
			|SELECT
			|	DocumentSales.PaymentDate    AS PaymentDate,
			|	100                            AS PaymentPercentage,
			|	DocumentSales.DocumentAmount AS PaymentAmount
			|FROM
			|	Document.WriteOffReportFromCommissionAgent AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
			
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		QueryText = "
			|SELECT
			|	PaymentScheduleSteps.Ref AS Ref,
			|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
			|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
			|	PaymentScheduleSteps.PaymentAmount AS PaymentAmount
			|FROM
			|	Document.CustomerInvoiceServices.PaymentScheduleSteps AS PaymentScheduleSteps
			|WHERE
			|	PaymentScheduleSteps.Ref = &Ref
			|	AND PaymentScheduleSteps.PaymentAmount > 0
			|
			|ORDER BY
			|	Ref";
			
	Else
		QueryText = "";
	EndIf;
	
		If Not IsBlankString(QueryText) Then
			
			If Object.PaymentScheduleSteps.Count() > 0 Then
				Object.PaymentScheduleSteps.Clear();
			EndIf;
			
			Query = New Query(QueryText);
			Query.SetParameter("Ref", Object.DocumentBasis);
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				NewStage = Object.PaymentScheduleSteps.Add();
				FillPropertyValues(NewStage, Selection);
			EndDo;
			
			Object.DocumentAmount = Object.PaymentScheduleSteps.Total("PaymentAmount");
			
		EndIf;
		
		SetPrivilegedMode(False);
	
	SetAvailabilityOfItemsForPartialPayment();
	
EndProcedure

&AtServer
Procedure PopulatePurposeOfPayment()
	
	DocumentBasis = Object.DocumentBasis;
	
	If Not IsBlankString(DocumentBasis) Then
		DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis, "Number, Date");
		Object.PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			DetailsOfFoundation.Number,
			DocumentBasis,
			DetailsOfFoundation.Date);
		
	Else
		PaymentPurposes = NStr("vi = 'Theo hóa đơn số %AccountNumber% ngày %InvoiceDate_%';
								|ru = 'По счету № %AccountNumber% от %InvoiceDate_%';
								|en = 'By account No.%AccountNumber% from %InvoiceDate_%'; fa = 'By account No.%AccountNumber% from %InvoiceDate_%';
								|it = 'In base alla fattura № %AccountNumber% del %InvoiceDate_%';
								|pl = 'Na podstawie rachunku nr %AccountNumber% z dnia %InvoiceDate_%';
								|tr = 'Hesap № %AccountNumber% %InvoiceDate_% tarihli'");
		PaymentPurposes = StrReplace(PaymentPurposes, 
			"%AccountNumber%", 
		ObjectsPrefixesClientServer.NumberForPrinting(Object.Number));
		PaymentPurposes = StrReplace(PaymentPurposes, "%InvoiceDate_%", Format(Object.Date, "DLF=D"));
		Object.PaymentPurposes = PaymentPurposes;
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
EndProcedure

&AtClient
Procedure InscriptionPaymentSBPURLProcessingCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
		SuccessfullyRecorded = Write(WriteParameters);
		
		If SuccessfullyRecorded Then
			CashClientLocalization.ProcessingOfNavigationLinkSBP(
				ThisObject, Object.Ref, AdditionalParameters.URL);
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ResponseBeforeWrite = False;

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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

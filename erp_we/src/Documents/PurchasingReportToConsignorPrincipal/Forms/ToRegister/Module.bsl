
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Items.ListOfAssignmentsForRegistrationIssueAReport.Enabled = AccessRight("Insert",Metadata.Documents.PurchasingReportToConsignorPrincipal);
	
	// Getting a FO
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	// Installation of selections.
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
							
	OptionOfAssignment = Constants.OptionOfGoodsAssignmentInSales.Get();
	
	TypesArray = New Array;
	If OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder Then
		
		TypesArray.Add(Type("DocumentRef.SalesOrder"));
		Items.Purpose.TypeRestriction = New TypeDescription(TypesArray);
		Items.Purpose.InputHint = NStr("vi = 'Đơn hàng';
										|ru = 'Заказ';
										|en = 'Order'; fa = 'سفارش';
										|it = 'Ordine';
										|pl = 'Order';
										|tr = 'Sipariş'");
		Items.ListOfAppointmentsToMakeAnAppointment.Title = NStr("vi = 'Đơn hàng của người đặt ký gửi (người ủy quyền)';
																|ru = 'Заказ комитента (принципала)';
																|en = 'Sales order'; fa = 'سفارش فروش';
																|it = 'Ordine del committente (mandante)';
																|pl = 'Zamówienie komitenta (zleceniodawcy)';
																|tr = 'Yetkili siparişi (iş veren)'");

		Items.PurposeListForRegistrationContractWithConsignor.Visible = True;
		
	ElsIf OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.Contract Then
		
		TypesArray.Add(Type("CatalogRef.CounterpartyContracts"));
		Items.Purpose.TypeRestriction = New TypeDescription(TypesArray);
		Items.Purpose.InputHint = NStr("vi = 'Hợp đồng';
										|ru = 'Договор';
										|en = 'Contract'; fa = 'قرارداد';
										|it = 'Accordo';
										|pl = 'Contract';
										|tr = 'Sözleşme'");
		Items.ListOfAppointmentsToMakeAnAppointment.Title = NStr("vi = 'Hợp đồng với người đặt ký gửi (ủy quyền)';
																|ru = 'Договор с комитентом (принципалом)';
																|en = 'Contract with consignor/principal'; fa = 'قرارداد با امانت‌گذار/موکل';
																|it = 'Accordo con il committente (mandante)';
																|pl = 'Umowa z komitentem (zleceniodawcą)';
																|tr = 'Gönderici (tedarikçi) ile sözleşme'");
		
		Items.PurposeListForRegistrationContractWithConsignor.Visible = False;
		
	Else
		Purpose = Undefined;
		Items.Purpose.Visible = False;
	EndIf;
		
	CommonClientServer.SetDynamicListParameter(PurposeListForRegistration, 
		"TheOptionOfSeparationIsUsedOnTheCustomerSOrder", OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder, True);
	
	CommonClientServer.SetDynamicListParameter(PurposeListForRegistration,
		"StateNotStarted", NStr("vi = 'Chưa bắt đầu';
								|ru = 'Не начат';
								|en = 'Not started'; fa = 'شروع‌نشده';
								|it = 'Non è iniziato';
								|pl = 'Nie rozpoczęto';
								|tr = 'Başlatılmadı'"));
	
	CommonClientServer.SetDynamicListParameter(List, 
		"TheOptionOfSeparationIsUsedOnTheCustomerSOrder", OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder, True);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization",     Organization);
		QuickFilterStructure.Property("Consignor",        Consignor);
		QuickFilterStructure.Property("Vendor",       Vendor);
		QuickFilterStructure.Property("Purpose",      Purpose);
	EndIf;
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.PurchasingReportToConsignorPrincipal"));
	
	SetDynamicListSelection();	
	SetCurrentPage();
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_VendorInvoice"
		Or EventName = "Write_PurchaseAdjustment"
		Or EventName = "Write_ReturnOfGoodsToVendor"
		Or EventName = "Write_PurchasingReportToConsignorPrincipal" Then
		
		Items.PurposeListForRegistration.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Vendor", Vendor);
		Settings.Delete("Vendor");
		QuickFilterStructure.Property("Consignor", Consignor);
		Settings.Delete("Consignor");
		QuickFilterStructure.Property("Purpose", Purpose);
		Settings.Delete("Purpose");
		QuickFilterStructure.Property("Organization", Organization);
		Settings.Delete("Organization");
	Else
		Vendor = Settings.Get("Vendor");
		Consignor = Settings.Get("Consignor");
		Purpose = Settings.Get("Purpose");
		If ValueIsFilled(Purpose) Then
			OptionOfAssignment = Constants.OptionOfGoodsAssignmentInSales.Get();
			If OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder
				And TypeOf(Purpose) = Type("CatalogRef.CounterpartyContracts") Then
				Purpose = Undefined;
			ElsIf OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.Contract
				And TypeOf(Purpose) = Type("DocumentRef.SalesOrder") Then
				Purpose = Undefined;
			EndIf;
		EndIf;
		Organization = Settings.Get("Organization");
	EndIf;
	
	Period = Settings.Get("Period");
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConsignorOnChange(Item)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Insert("Consignor", Consignor);
	EndIf;	
	SetDynamicListSelection();
		
EndProcedure

&AtClient
Procedure VendorOnChange(Item)
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Insert("Vendor", Vendor);
	EndIf;
	SetDynamicListSelection();
		
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Insert("Purpose", Purpose);
	EndIf;
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Insert("Organization", Organization);
	EndIf;	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure HyperlinkSalesLogURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "");
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.DocumentsList", FormParameters);
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
		
	If CurrentPage = Items.GroupToRegister Then
		
		Items.Vendor.Visible = True;
		Items.Purpose.Visible = True;
			
		Items.PurposeListForRegistration.Refresh();
		
	ElsIf CurrentPage = Items.PagePurchasingReportsToConsignors Then
		
		Items.Vendor.Visible = False;
		Items.Purpose.Visible = False;
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		StructureFilter = New Structure;
		StructureFilter.Insert("Organization", Organization);
		StructureFilter.Insert("Partner", Consignor);
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.PurchasingReportToConsignorPrincipal.Form.DocumentForm", ParametersStructure1, Items.List);
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure IssueAReportToTheCommiteeOnPurchases(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.PurchasingReportToConsignorPrincipal.Form.ToRegister.Command.IssueAReportToTheCommiteeOnPurchases");
	
	IssueReportToCommitteeOnPurchasesOnClient();
		
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Other

&AtServer
Procedure SetDynamicListSelection()
	
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Partner",
		Consignor,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignor));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	
	CommonClientServer.SetDynamicListFilterItem(
		PurposeListForRegistration,
		"Consignor",
		Consignor,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignor));
		
	CommonClientServer.SetDynamicListFilterItem(
		PurposeListForRegistration,
		"Vendor",
		Vendor,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Vendor));
		
	CommonClientServer.SetDynamicListFilterItem(
		PurposeListForRegistration,
		"DimensionAssignments",
		Purpose,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Purpose));
		
	CommonClientServer.SetDynamicListFilterItem(
		PurposeListForRegistration,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
		
	SetSelectionByPeriod();
		
EndProcedure

#EndRegion

#Region Private

#Region FormItemsManagement

&AtServer
Procedure SetCurrentPage()
	
	CurrentPageName = "";
	If Not Parameters.Property("CurrentPageName", CurrentPageName) Then
		CurrentPageName = Items.PurposeListForRegistration.Name;	
	EndIf;	
	
	If ValueIsFilled(CurrentPageName) Then
		CurrentItem = Items[CurrentPageName];
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Conditional design of the dynamic list "List of assignments"
	ListOfConditionalAppearance = PurposeListForRegistration.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
EndProcedure

#Region CreatingNewDocuments

&AtClient
Procedure IssueReportToCommitteeOnPurchasesOnClient()
	
	ClearMessages();
	
	SelectedRows = Items.PurposeListForRegistration.SelectedRows;
	PurposeList.Clear();
	
	For Each String In SelectedRows Do
		FoundRow = Items.PurposeListForRegistration.RowData(String);
		AddedRow = PurposeList.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters
	ParametersOfCreatedDocuments = SubmitReportToCommitteeAboutPurchasesOnServer();
	If ParametersOfCreatedDocuments.Property("IssueNumberOfInvoices") And ParametersOfCreatedDocuments.IssueNumberOfInvoices Then
		TimeConsumingOperation = ParametersOfCreatedDocuments.TimeConsumingOperation;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackDescription = New CallbackDescription("IssueReportToCommitteeOnPurchasesOnClientCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	Else
		IssueReportToCommitteeOnPurchasesOnClientCompletion(Undefined, ParametersOfCreatedDocuments);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueReportToCommitteeOnPurchasesOnClientCompletion(Result, AddlParameters) Export
	
	If Result = Undefined Then
		ParametersOfCreatedDocuments = AddlParameters;
	Else
		ParametersOfCreatedDocuments = GetFromTempStorage(Result.ResultAddress);
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, 
				ThisObject,
				ParametersOfCreatedDocuments),
			ParametersOfCreatedDocuments.TextOfQuestionToUser,
			QuestionDialogMode.YesNo);
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
		EndIf;
		OpenForm(ParametersOfCreatedDocuments.FormName, 
			ParametersOfCreatedDocuments.Parameters,
			ThisForm,,,,,);
	EndIf;
	
	Items.PurposeListForRegistration.Refresh();
	
EndProcedure

&AtServer
Function SubmitReportToCommitteeAboutPurchasesOnServer()
	
	Var ErrorList;
	
	FormParameters = New Structure();
	FormParameters.Insert("IssueNumberOfReportsToPurchasingCommittee", False);
	FormParameters.Insert("TimeConsumingOperation", Undefined);
	FormParameters.Insert("ErrorList", ErrorList);
	
	// Breakdown of selected lines for different reports to the committee
	BreakdownResults = SplitListOfAppointmentsByReports();
	BreakdownByDocuments = BreakdownResults.ArrayOfTables;
	DataOnDiscrepancies = BreakdownResults.DataOnDiscrepancies;
	
	TotalTables = BreakdownByDocuments.Count();
	
	// The form of the created invoice opens, if the key fields of the selected lines match, and the functional option allows
	// Otherwise, a form opens with a list of created invoices
	
	If TotalTables > 0 Then
		If BreakdownByDocuments.Count() > 1 Then
			
			ErrorText = "";
			
			If DataOnDiscrepancies.VariousOrganizations Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- cho doanh nghiệp';
														|ru = '- организациям';
														|en = '- companies'; fa = '- companies';
														|it = '- организациям';
														|pl = '- companies';
														|tr = '- iş yerlerine'");
			EndIf;
			
			If DataOnDiscrepancies.VariousCommittees Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- cho người đặt ký gửi';
														|ru = '- комитентам (принципалам)';
														|en = '- consignors (principals)'; fa = '- consignors (principals)';
														|it = '- комитентам (принципалам)';
														|pl = '- consignors (principals)';
														|tr = '- göndericiler'");
			EndIf;
			
			If DataOnDiscrepancies.VariousContracts Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- hợp đồng';
														|ru = '- договорам';
														|en = '- contracts'; fa = '- contracts';
														|it = '- договорам';
														|pl = '- contracts';
														|tr = '- sözleşmeler'");
			EndIf;
			
			If DataOnDiscrepancies.DifferentCurrency_0 Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- cho tiền tệ';
														|ru = '- валютам';
														|en = '- currencies'; fa = '- currencies';
														|it = '- валютам';
														|pl = '- currencies';
														|tr = '- para birimleri'");
			EndIf;
			
			If DataOnDiscrepancies.VariousActivities Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- lĩnh vực hoạt động';
														|ru = '- направлениям деятельности';
														|en = '- lines of business'; fa = '- lines of business';
														|it = '- per settori di attività';
														|pl = '-  dla rodzajów działalności';
														|tr = '- iş kolları'");
			EndIf;
			
			If DataOnDiscrepancies.DifferentVATTaxation Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- Tùy chọn thuế Thuế GTGT';
														|ru = '- вариантам налогообложения НДС';
														|en = '- VAT taxation options'; fa = '- VAT taxation options';
														|it = '- per opzioni di tassazione IVA';
														|pl = '- dla wariantów opodatkowania VAT';
														|tr = '- KDV vergilendirmesi seçeneği'");
			EndIf;
			
			If DataOnDiscrepancies.DifferentSettingsByPriceIncludesVAT Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- tùy chọn để phản ánh Thuế GTGT trong giá';
														|ru = '- вариантам отражения НДС в цене';
														|en = '- options of VAT posting in price'; fa = '- options of VAT posting in price';
														|it = '- per opzioni di visualizzazione IVA nel prezzo';
														|pl = '- dla wariantów odzwierciedlenia VAT w cenie';
														|tr = '- KDV''yi fiyata yansıtma seçenekleri'");
			EndIf;
			
			If DataOnDiscrepancies.DifferentSettingsByConvention Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- thỏa thuận trong đơn hàng của bên giao hàng ký gửi';
														|ru = '- соглашениям в заказах принципала';
														|en = '- agreements in the principal''s orders'; fa = '- agreements in the principal''s orders';
														|it = '- per accordi negli ordini del mandante';
														|pl = '- dla umów w zamówieniach w zleceniodawcy';
														|tr = '- iş veren siparişlerindeki anlaşmalar'");
			EndIf;
			
			If DataOnDiscrepancies.DifferentSettingsForPurchaseDocument Then
				ErrorText = ErrorText + Chars.LF+ NStr("vi = '- mua hàng, khi bật sử dụng chia tách mua hàng trong báo cáo';
														|ru = '- приобретениям, при включенной разбивке по приобретениям в отчете';
														|en = '- purchases, when the split by purchases is enabled in the report'; fa = '- purchases, when the split by purchases is enabled in the report';
														|it = '- acquisizioni, quando nel rapporto è inclusa una ripartizione per acquisizioni';
														|pl = '- dla zakupu, przy włączonym podziale według zakupu w raporcie';
														|tr = '- satın almalar, satın almalara göre bir dağılım rapora dahil edildiğinde'");
			EndIf;
			
			If Not ErrorText = "" Then
				ErrorText = NStr("vi = 'Không thể lập bảng kê mua hàng do nhiều nguyên nhân:';
								|ru = 'Недоступно оформление отчета о закупках по различным:';
								|en = 'Registering purchasing report is not available due to various reasons:'; fa = 'Registering purchasing report is not available due to various reasons:';
								|it = 'Impossibile generare il report sugli acquisti per diversi:';
								|pl = 'Niedostępne sporządzenie raportu o zakupach wg różnych:';
								|tr = 'Çeşitli kalemlere ilişkin bir satın alma raporu düzenlenemiyor:'")+ErrorText;
				CommonClientServer.AddUserError(ErrorList, "Object.PurposeListForRegistration", ErrorText, Undefined);
			EndIf;
			
		ElsIf BreakdownByDocuments.Count() = 1 Then
			// Individually
			FormParameters = IssueReportToCommitteeOnPurchasesAccordingToTable(BreakdownByDocuments, ErrorList);
		EndIf;
	ElsIf PurposeList.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Không có chứng từ nào được chọn có thể được thực thi %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																							|ru = 'по заказам';
																							|en = 'by orders'; fa = 'by orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		Items.PurposeListForRegistration.Refresh();
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

&AtServer
Function SplitListOfAppointmentsByReports()
	
	SplitReportByDocuments = False;
	RowsSelected = PurposeList.Unload(,"ContractWithConsignor");
	RowsSelected.GroupBy("ContractWithConsignor");
	
	For Each String In RowsSelected Do
		If ValueIsFilled(String.ContractWithConsignor) Then
			SplitReportByDocuments = SplitReportByDocuments Or Common.ObjectAttributeValue(String.ContractWithConsignor, "SplitReportByDocuments");
		EndIf;
	EndDo;
	
	ColumnsForUnloading = "Organization, Consignor, ContractWithConsignor, CounterpartyCommitee, Currency, LineOfBusiness, VATTaxation, PriceIncludesVAT, Terms";
	If SplitReportByDocuments Then
		ColumnsForUnloading = ColumnsForUnloading + ", DocumentAcquisitions";
	EndIf;
	
	UniqueDocumentParameters = PurposeList.Unload(,ColumnsForUnloading);
	UniqueDocumentParameters.GroupBy(ColumnsForUnloading, "");
	If Not SplitReportByDocuments Then
		UniqueDocumentParameters.Columns.Add("DocumentAcquisitions", New TypeDescription("DocumentRef.VendorInvoice"));
	EndIf;
	
	ArrayOfTables = New Array();
	For Each DocumentParameterString In UniqueDocumentParameters Do
		
		SelectionForListOfAppointments = New Structure;
		SelectionForListOfAppointments.Insert("Organization", DocumentParameterString.Organization);
		SelectionForListOfAppointments.Insert("Consignor", DocumentParameterString.Consignor);
		SelectionForListOfAppointments.Insert("Currency", DocumentParameterString.Currency);
		SelectionForListOfAppointments.Insert("ContractWithConsignor", DocumentParameterString.ContractWithConsignor);
		SelectionForListOfAppointments.Insert("CounterpartyCommitee", DocumentParameterString.CounterpartyCommitee);
		SelectionForListOfAppointments.Insert("LineOfBusiness", DocumentParameterString.LineOfBusiness);
		SelectionForListOfAppointments.Insert("VATTaxation", DocumentParameterString.VATTaxation);
		SelectionForListOfAppointments.Insert("PriceIncludesVAT", DocumentParameterString.PriceIncludesVAT);
		SelectionForListOfAppointments.Insert("Terms", DocumentParameterString.Terms);
		If SplitReportByDocuments Then
			SelectionForListOfAppointments.Insert("DocumentAcquisitions", DocumentParameterString.DocumentAcquisitions);
		EndIf;
		RowsInListOfSelectionAssignments = PurposeList.FindRows(SelectionForListOfAppointments);
		ArrayOfTables.Add(PurposeList.Unload(RowsInListOfSelectionAssignments));
		
	EndDo;
	
	DataOnDiscrepancies = GetDataOnDiscrepancyBetweenDetailsOfSelectedDocuments(UniqueDocumentParameters);
	
	Result = New Structure();
	Result.Insert("ArrayOfTables", ArrayOfTables);
	Result.Insert("DataOnDiscrepancies", DataOnDiscrepancies);
	
	Return Result;
EndFunction

&AtServerNoContext
Function GetDataOnDiscrepancyBetweenDetailsOfSelectedDocuments(UniqueDocumentParameters)
	Query = New Query();
	Query.Text = "SELECT
	               |	DocumentParameterTable.Organization AS Organization,
	               |	DocumentParameterTable.Consignor AS Consignor,
	               |	DocumentParameterTable.ContractWithConsignor AS ContractWithConsignor,
	               |	DocumentParameterTable.CounterpartyCommitee AS CounterpartyCommitee,
	               |	DocumentParameterTable.Currency AS Currency,
	               |	DocumentParameterTable.LineOfBusiness AS LineOfBusiness,
	               |	DocumentParameterTable.VATTaxation AS VATTaxation,
	               |	DocumentParameterTable.PriceIncludesVAT AS PriceIncludesVAT,
	               |	DocumentParameterTable.Terms AS Terms,
	               |	DocumentParameterTable.DocumentAcquisitions AS DocumentAcquisitions
	               |	
	               |INTO DocumentParameterTable
	               |FROM
	               |	&DocumentParameterTable AS DocumentParameterTable
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	COUNT(DISTINCT DocumentParameterTable.Organization) AS Organization,
	               |	COUNT(DISTINCT DocumentParameterTable.Consignor) AS Consignor,
	               |	COUNT(DISTINCT DocumentParameterTable.ContractWithConsignor) AS ContractWithConsignor,
	               |	COUNT(DISTINCT DocumentParameterTable.CounterpartyCommitee) AS CounterpartyCommitee,
	               |	COUNT(DISTINCT DocumentParameterTable.Currency) AS Currency,
	               |	COUNT(DISTINCT DocumentParameterTable.LineOfBusiness) AS LineOfBusiness,
	               |	COUNT(DISTINCT DocumentParameterTable.VATTaxation) AS VATTaxation,
	               |	COUNT(DISTINCT DocumentParameterTable.PriceIncludesVAT) AS PriceIncludesVAT,
	               |	COUNT(DISTINCT DocumentParameterTable.Terms) AS Terms,
	               |	COUNT(DISTINCT CASE
	               |		WHEN Contracts.Ref IS NULL
	               |			THEN VALUE(Document.VendorInvoice.EmptyRef)
	               |		ELSE DocumentParameterTable.DocumentAcquisitions
	               |	END) AS DocumentAcquisitions
	               |INTO TableOfNumberOfDifferent
	               |FROM
	               |	DocumentParameterTable AS DocumentParameterTable
	               |	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	               |		ON Contracts.Ref = DocumentParameterTable.ContractWithConsignor
	               |		AND Contracts.SplitReportByDocuments
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.Organization > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS VariousOrganizations,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.Consignor > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS VariousCommittees,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.ContractWithConsignor > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS VariousContracts,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.CounterpartyCommitee > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS VariousCounterparties,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.Currency > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS DifferentCurrency_0,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.LineOfBusiness > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS VariousActivities,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.VATTaxation > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS DifferentVATTaxation,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.PriceIncludesVAT > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS DifferentSettingsByPriceIncludesVAT,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.Terms > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS DifferentSettingsByConvention,
	               |	CASE
	               |		WHEN TableOfNumberOfDifferent.DocumentAcquisitions > 1
	               |			THEN TRUE
	               |		ELSE FALSE
	               |	END AS DifferentSettingsForPurchaseDocument
	               |FROM
	               |	TableOfNumberOfDifferent AS TableOfNumberOfDifferent";
	Query.SetParameter("DocumentParameterTable", UniqueDocumentParameters);
	
	InformationOnVariousDataOfSelectedDocuments = New Structure();
	InformationOnVariousDataOfSelectedDocuments.Insert("VariousOrganizations",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("VariousCommittees",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("VariousContracts",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("VariousCounterparties",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("DifferentCurrency_0",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("VariousActivities",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("DifferentVATTaxation",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("DifferentSettingsByPriceIncludesVAT",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("DifferentSettingsByConvention",False);
	InformationOnVariousDataOfSelectedDocuments.Insert("DifferentSettingsForPurchaseDocument",False);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(InformationOnVariousDataOfSelectedDocuments, Selection);
	EndIf;

	Return InformationOnVariousDataOfSelectedDocuments;
EndFunction

&AtServer
Function IssueReportToCommitteeOnPurchasesAccordingToTable(BreakdownByDocuments, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = BreakdownByDocuments[0];
	FirstRow  = DocumentsTable[0];
	
	MetadataOfReportToPurchasingCommittee = Metadata.Documents.PurchasingReportToConsignorPrincipal;
	NameOfReportToPurchasingCommittee        = MetadataOfReportToPurchasingCommittee.Name;
	
	FormSettings = New Structure();
	FormParameters = New Structure();

	Assignments = DocumentsTable.UnloadColumn("Purpose");
	AcquisitionDocuments = DocumentsTable.UnloadColumn("DocumentAcquisitions");
	
	TheStructureOfTheSearch = Documents.PurchasingReportToConsignorPrincipal.StructureOfMeaningfulProps();
	TheStructureOfTheSearch.Partner = FirstRow.Consignor;
	TheStructureOfTheSearch.Organization = FirstRow.Organization;
	TheStructureOfTheSearch.Contract = FirstRow.ContractWithConsignor;
	TheStructureOfTheSearch.Counterparty = FirstRow.CounterpartyCommitee;
	TheStructureOfTheSearch.Currency = FirstRow.Currency;
	TheStructureOfTheSearch.DocumentAcquisitions = FirstRow.DocumentAcquisitions;
	
	FillPropertyValues(TheStructureOfTheSearch, FirstRow);
	
	HeaderAttributes = New Structure();
	TMCommonUseClientServer.SupplementStructure(HeaderAttributes, TheStructureOfTheSearch, True);
	
	FormParameters.Insert("HeaderAttributes",    HeaderAttributes);
	FormParameters.Insert("AssignmentsArray",     Assignments);
	FormParameters.Insert("ArrayOfPurchaseDocuments",     AcquisitionDocuments);
	FormParameters.Insert("FillInAccordingToDataForRegistration", True);
	
	FormSettings.Insert("FormName", "Document." + NameOfReportToPurchasingCommittee + ".Form.DocumentForm");
	
	// To display a message about the number of documents created
	CreatedDocuments.Add(PredefinedValue("Document." + MetadataOfReportToPurchasingCommittee.Name + ".EmptyRef"));
	
	FormParameters.Insert("CreatedDocuments", CreatedDocuments);
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	Return FormSettings;
	
EndFunction

#EndRegion

#EndRegion

#Region Variables

&AtClient
Var MatchingCommandsAndDisplayModes;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not InfobaseUpdate.ObjectProcessed("InformationRegister.JobsForAllocatingARAP").Processed Then
		Common.MessageToUser(NStr("vi = 'Chú ý, hiện đang cập nhật dữ liệu cơ sở thông tin. 
			|Trước khi kết thúc cập nhật, dữ liệu thu và chi tiền dự tính về hạch toán công nợ có thể chưa chính xác.';
			|ru = 'Внимание, в настоящее время производится обновление данных информационной базы. 
			|До окончания обновления сведения об ожидаемых поступлениях и списаниях по взаиморасчетам могут быть неактуальны.';
			|en = 'Important. At the moment, the system is updating the infobase data. 
			|Until the update is completed, information on expected AR/AP receipts and write-offs might be outdated.'; fa = 'Important. At the moment, the system is updating the infobase data. 
			|Until the update is completed, information on expected AR/AP receipts and write-offs might be outdated.';
			|it = 'Внимание, в настоящее время производится обновление данных информационной базы. 
			|До окончания обновления сведения об ожидаемых поступлениях и списаниях по взаиморасчетам могут быть неактуальны.';
			|pl = 'Important. At the moment, the system is updating the infobase data. 
			|Until the update is completed, information on expected AR/AP receipts and write-offs might be outdated.';
			|tr = 'Dikkat, infobase verileri şu anda güncelleniyor. 
			|Güncellemenin sonuna kadar, mutabakat için beklenen girişler ve gider yazmalar hakkındaki bilgiler güncel olmayabilir.'"))
	EndIf;
	
	SetConditionalAppearance();
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.TableFieldFilling, "ReportGeneration");
	
	MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
	Object.PlanFromDate = CurrentSessionDate();
	Object.PlanningDays = 5;
	Object.LongTermPlanningTimeFence = Enums.Periodicity.Month;
	Object.ZeroBalancesAndTurnover = True;
	
	DataProcessors.CashForecast.FillInEndDates(Object);
	CommonClientServer.SetDynamicListParameter(PaymentsInTheCalendar, "TaggedEntries",
		TaggedPaymentEntriesInCalendar);
	CommonClientServer.SetDynamicListParameter(PaymentRequests, "TaggedEntries",
		MarkedEntriesOfAmountDueRequest);
	
	If Not GetFunctionalOption("UseLoanAndDepositContracts") Then
		Object.LoansOrBorrowingsReceived = False;
		Object.Deposits = False;
		Object.IssuedBorrowings = False;
	EndIf;
	If Not NonCurrentAssets.VNAManagementIsUsed() Then
		Object.Lease = False;
	EndIf;
	DataProcessors.CashForecast.InitializeSettingsComposer(Object.LinkerSelection, UUID);
	InitializeOrganizationSelection();
	
	FiltersDetails = New Map;
	FiltersDetails.Insert("Organization", Type("CatalogRef.Companies"));
	AccessManagement.SetDynamicListFilters(PaymentRequests, FiltersDetails);
	AccessManagement.SetDynamicListFilters(PaymentsInTheCalendar, FiltersDetails);
	
	FilterPlanningAreas.Add(Enums.PaymentPlanningAreas.CashPaymentRequests);
	FilterPlanningAreas.Add(Enums.PaymentPlanningAreas.ReferencesForCashTransfer);
	FilterPlanningAreas.Add(Enums.PaymentPlanningAreas.CashInTransit);
	
	Object.TotalCurrency = Constants.ManagementAccountingCurrency.Get();
	
	Object.ReportDimensions.Add("Currency",				 NStr("vi = 'Tiền tệ';
																|ru = 'Валюта';
																|en = 'Currency'; fa = 'ارز';
																|it = 'Valuta';
																|pl = 'Waluta';
																|tr = 'Para birimi'"));
	Object.ReportDimensions.Add("Organization",		 NStr("vi = 'Doanh nghiệp';
															|ru = 'Организация';
															|en = 'Company'; fa = 'Company';
															|it = 'Azienda';
															|pl = 'Firma';
															|tr = 'İş yeri'"));
	Object.ReportDimensions.Add("CashType",  NStr("vi = 'Kiểu vốn bằng tiền';
													|ru = 'Тип денежных средств';
													|en = 'Cash type'; fa = 'نوع وجه نقد';
													|it = 'Tipo di fondi monetari';
													|pl = 'Typ środków pieniężnych';
													|tr = 'Nakit tipi'"));
	Object.ReportDimensions.Add("CashAccountBank",			 NStr("vi = 'Ngân hàng';
																	|ru = 'Банк';
																	|en = 'Bank'; fa = 'بانک';
																	|it = 'Bank';
																	|pl = 'Bank';
																	|tr = 'Banka'"));
	Object.ReportDimensions.Add("BankAccountCashAccount", NStr("vi = 'Tài khoản ngân hàng / Tiền mặt';
																|ru = 'Банковский счет / Касса';
																|en = 'Bank account / Cash account'; fa = 'حساب بانکی / صندوق';
																|it = 'Conto bancario / Cassa';
																|pl = 'Rachunek bankowy / Kasa';
																|tr = 'Banka hesabı / Kasa'"), True);
	
	TreeItemsWithoutAddedDays = GetAttributes("Object.PaymentTree").Count();
	
	Items.ModeApplicationsCalendar.Title = NStr("vi = 'Đơn';
												|ru = 'Заявки';
												|en = 'Requests'; fa = 'درخواست‌ها';
												|it = 'Richieste';
												|pl = 'Requests';
												|tr = 'Başvurular'") + " " + Char(8594) + " " + NStr("vi = 'Lịch';
																									|ru = 'Календарь';
																									|en = 'Cash forecast'; fa = 'پیش‌بینی وجه نقد';
																									|it = 'Calendario';
																									|pl = 'Cash forecast';
																									|tr = 'Takvim'");
	Items.ModeCalendarPayments.Title = NStr("vi = 'Lịch';
											|ru = 'Календарь';
											|en = 'Cash forecast'; fa = 'پیش‌بینی وجه نقد';
											|it = 'Calendario';
											|pl = 'Kalendarz';
											|tr = 'Takvim'") + " " + Char(8594) + " " + NStr("vi = 'Diễn giải';
																									|ru = 'Расшифровка';
																									|en = 'Drill-down'; fa = 'جزئیات بیشتر';
																									|it = 'Drill-down';
																									|pl = 'Drill-down';
																									|tr = 'Ayrıntılar'");
	Items.ModeRequestList.Title = NStr("vi = 'Danh sách các Đơn';
										|ru = 'Список заявок';
										|en = 'Request list'; fa = 'فهرست درخواست‌ها';
										|it = 'Elenco delle richieste';
										|pl = 'Lista wniosków';
										|tr = 'Başvuru listesi'");
	
	If GetFunctionalOption("UsePaymentRequests") Then
		
		ViewMode = "ApplicationsCalendar";
		CurrentListName = "PaymentRequests";
		NameOfCurrentListOfTaggedEntries = "MarkedEntriesOfAmountDueRequest";
	Else
		ViewMode = "CalendarPayments";
		CurrentListName = "PaymentsInTheCalendar";
		NameOfCurrentListOfTaggedEntries = "TaggedPaymentEntriesInCalendar";
		
		Items.ModeApplicationsCalendar.Visible = False;
		Items.ModeRequestList.Visible = False;
		Items.PlanningGroup_5.Visible = False;
		Items.PaymentsInTheCalendarGroupingPriorityOfTheRequest.Visible = False;
		
		Object.RequestsPendingApproval = False;
		Object.PlannedCashReceipts = False;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.PaymentRequestsOrganization.Visible = False;
		Items.PaymentsInTheCalendarOrganization.Visible = False;
		Items.FilterCompanies.Visible = False;
		
		GroupingCompany = Object.ReportDimensions.FindByValue("Organization");
		If GroupingCompany <> Undefined Then
			Object.ReportDimensions.Delete(GroupingCompany);
		EndIf;
		
		OrganizationField_ = New DataCompositionField("Organization");
		For Each FilterElement In Object.LinkerSelection.Settings.Filter.Items Do
			If TypeOf(FilterElement) <> Type("DataCompositionFilterItemGroup")
				And FilterElement.LeftValue = OrganizationField_ Then
				Object.LinkerSelection.Settings.Filter.Items.Delete(FilterElement);
			EndIf;
		EndDo;
	EndIf;
	
	If SystemSettingsStorage.GetDescription("DataProcessor.CashForecast.Form.Form/CurrentData") = Undefined Then
		UpdateListsOnServer();
		InitializeTheMenuOfGroupingLevels();
		SelectionOfApplicationsWhenChangingOnServer();
	EndIf;
	
	MarkInvoiceFilter();
	ChangeFormItemsVisibility();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DataProcessors.CashForecast.FillInEndDates(Object);
	
	For Each FilterElement In FilterCompanies Do
		If Object.FilterCompanies.FindByValue(FilterElement.Value) = Undefined Then
			Object.FilterCompanies.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	Indus = Object.FilterCompanies.Count() - 1;
	While Indus >= 0 Do
		If FilterCompanies.FindByValue(Object.FilterCompanies[Indus].Value) = Undefined Then
			Object.FilterCompanies.Delete(Indus);
		EndIf;
		Indus = Indus - 1;
	EndDo;
	
	FilterCompaniesPresentation = FilterPresentation(Object.FilterCompanies);
	FilterBankAccountCashAccountPresentation = FilterPresentation(Object.FilterBankAccountsCashAccounts);
	
	Items.ApplicationsToDistribution.Check = PickRequests;
	
	AvailableModes = New Array;
	AvailableModes.Add("ApplicationsCalendar");
	AvailableModes.Add("RequestList");
	AvailableModes.Add("CalendarPayments");
	
	If GetFunctionalOption("UsePaymentRequests") Then
	
		If AvailableModes.Find(ViewMode) = Undefined Then
			ViewMode = "ApplicationsCalendar";
		EndIf;
	Else
		ViewMode = "CalendarPayments";
		Object.RequestsPendingApproval = False;
		Object.PlannedCashReceipts = False;
	EndIf;
	
	If ViewMode = "ApplicationsCalendar" Or ViewMode = "RequestList" Then
		CurrentListName = "PaymentRequests";
		NameOfCurrentListOfTaggedEntries = "MarkedEntriesOfAmountDueRequest";
	Else
		CurrentListName = "PaymentsInTheCalendar";
		NameOfCurrentListOfTaggedEntries = "TaggedPaymentEntriesInCalendar";
	EndIf;
	
	DataProcessor = FormAttributeToValue("Object");
	FilterPlanningAreas.LoadValues(DataProcessor.PlanningAreas());
	
	If Not ValueIsFilled(Settings["Object.GroupDocumentsWhenCreating"]) Then
		Object.GroupDocumentsWhenCreating = True;
	EndIf;
	
	If Not ValueIsFilled(Settings["Object.ZeroBalancesAndTurnover"]) Then
		Object.ZeroBalancesAndTurnover = True;
	EndIf;
	
	If Not ValueIsFilled(Settings["Object.LongTermPlanningTimeFence"]) Then
		Object.LongTermPlanningTimeFence = Enums.Periodicity.Month;
	EndIf;
	
	If ValueIsFilled(Settings["CompactMode"]) And Settings["CompactMode"] Then
		Items.SwitchZoomModeOfView.Check = True;
		Scale = CompactModeScale();
	EndIf;
	
	If ValueIsFilled(Settings["FrozenPayments"]) And Settings["FrozenPayments"] Then
		Items.FrozenPayments.Check = True;
		Items.ApplicationsAmountDueFrozenPayments.Check = True;
	EndIf;
	
	If Not ValueIsFilled(Settings["Object.LinkerSelection.Settings.Filter"]) Then
		InstallComposerSelectionByCompanySelection(Object.LinkerSelection, Object.FilterCompanies);
		InstallComposerSelectionBySelectionCurrency(Object.LinkerSelection, Object.FilterCurrency);
		InstallComposerSelectionBySelectionBankAccountsCashAccounts(Object.LinkerSelection, Object.FilterBankAccountsCashAccounts);
	EndIf;
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		If ValueIsFilled(Settings["Object.ReportDimensions"]) Then
			GroupingCompany = Object.ReportDimensions.FindByValue("Organization");
			If GroupingCompany = Undefined Then
				Object.ReportDimensions.Insert(1, "Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Company';
																		|pl = 'Company';
																		|tr = 'İş yeri'"));
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(Settings["Object.ReportDimensions"]) Then
			GroupingCompany = Object.ReportDimensions.FindByValue("Organization");
			If GroupingCompany <> Undefined Then
				Object.ReportDimensions.Delete(GroupingCompany);
			EndIf;
		EndIf;
		
		OrganizationField_ = New DataCompositionField("Organization");
		If ValueIsFilled(Settings["Object.LinkerSelection.Settings.Filter"]) Then
			For Each FilterElement In Object.LinkerSelection.Settings.Filter.Items Do
				If TypeOf(FilterElement) <> Type("DataCompositionFilterItemGroup")
					And FilterElement.LeftValue = OrganizationField_ Then
					Object.LinkerSelection.Settings.Filter.Items.Delete(FilterElement);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	UpdateListsOnServer();
	InitializeTheMenuOfGroupingLevels();
	
	If ViewMode = "CalendarPayments" Then
		TreeRows = Object.PaymentTree.GetItems();
		If TreeRows.Count() Then
		
			CurrentData = TreeRows[0];
			CurrentTreeRow = CurrentData.GetID();
			CurrentTreeColumn = "PaymentTreeGroup";
			
			CurrentTreeGrouping = CurrentData.Group;
			CurRowOfTreeIsNotDistributed = CurrentData.UnallocatedLine;
			CurRowOfTreeIsDistributed = CurrentData.StringIsDistributed;
			CurrentBankAccountCashAccount = CurrentData.BankAccountCashAccount;
			CurrentCurrency = CurrentData.Currency;
			CurrentLineKind = CurrentData.LineKind;
			CurrentMovementType = CurrentData.ReceiptIssue;
			CurrentCompany = CurrentData.Organization;
			CurrentTypeOfFunds = CurrentData.CashType;
			CurBank = CurrentData.CashAccountBank;
			
			SetCalendarPaymentsSelectionAtServer();
			CalendarCellActivationOnDraggingIsDisabled = True;
		EndIf;
	EndIf;
	
	MarkInvoiceFilter();
	ChangeFormItemsVisibility();
	
	SelectionOfApplicationsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ManagingHistoryElements();
	
	SetCorrespondenceOfDisplayModesToCommands();
	
	ConfigureDisplayOfDimensions();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_PaymentRequest"
		Or EventName = "Write_CashTransferReferenceOrder"
		Or EventName = "Write_PlannedCashReceipt"
		Or EventName = "Write_CustomerInvoiceServicesAndAssets"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "PaymentScheduleLinesPaid" Then
		
		UpdatedList_4();
		
		If Not (ViewMode = "RequestList"
			Or ViewMode = "ApplicationsCalendar") Then
			Items.PaymentsInTheCalendar.Refresh();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentsInTheCalendar

&AtClient
Procedure PaymentsInTheCalendarOnActivateCell(Item)
	
	If Item.CurrentItem <> Undefined Then
			
		CurrentData = Item.CurrentData;
		If CurrentData <> Undefined Then
			
			TextApplicationWasNotCreated = NStr("vi = 'Để thực hiện thanh toán, cần lập giấy đề nghị chi tiền.';
												|ru = 'Для оплаты требуется оформить заявку на расходование денежных средств.';
												|en = 'To make a payment, register a payment request.'; fa = 'To make a payment, register a payment request.';
												|it = 'To make a payment, register a payment request.';
												|pl = 'To make a payment, register a payment request.';
												|tr = 'Ödeme için ödeme talebi oluşturulması gerekiyor.'");
			TextOriginalPaymentDateIsLessThanRescheduledOne =
				NStr("vi = 'Khoản thanh toán đã được chuyển sang ngày muộn hơn so với ngày đã thiết lập trong chứng từ.';
					|ru = 'Платеж перенесен на дату позже, даты установленной в документе.';
					|en = 'The payment is postponed to a date later than the date specified in the document.'; fa = 'The payment is postponed to a date later than the date specified in the document.';
					|it = 'The payment is postponed to a date later than the date specified in the document.';
					|pl = 'The payment is postponed to a date later than the date specified in the document.';
					|tr = 'Ödeme, belgede belirlenen tarihten ileri bir tarihe taşınmıştır.'");
			ErrorTextOfCurrentCell = "";
			ErrorsTexts = New Array;
			
			If CurrentData.Property("ThereIsErrorApplicationWasNotCreated") And CurrentData.ThereIsErrorApplicationWasNotCreated Then
				ErrorsTexts.Add(TextApplicationWasNotCreated);
			EndIf;
			
			If CurrentData.Property("ThereIsInitialPaymentDateLessThanRescheduledOne")
				And CurrentData.ThereIsInitialPaymentDateLessThanRescheduledOne Then
				ErrorsTexts.Add(TextOriginalPaymentDateIsLessThanRescheduledOne);
			EndIf;
			
			If ErrorsTexts.Count() Then
				ErrorTextOfCurrentCell = StrConcat(ErrorsTexts, " ");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentsInTheCalendarDragStart(Item, DragParameters, Perform)
	
	MarkedEntriesStartDragging(Item, DragParameters, Perform);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentTree

&AtClient
Procedure PaymentTreeDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If Field = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	ColumnName = New Structure("FieldName", Field.Name);
	If (Days.FindRows(ColumnName).Count() = 0 And LongTermPeriods.FindRows(ColumnName).Count() = 0)
		Or Field.Name = "PaymentTreeStretching" Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	If String = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	CurrentRow = Object.PaymentTree.FindByID(String);
	
	If Not CurrentRow.AvailableForTransfer Then
		DragParameters.Action = DragAction.Cancel;
	ElsIf String = CurrentTreeRow
		And Field.Name = CurrentTreeColumn Then
		DragParameters.Action = DragAction.Cancel;
	ElsIf CurrentRow.BankAccountCashAccount = CurrentBankAccountCashAccount
		And Field.Name = CurrentTreeColumn Then
		DragParameters.Action = DragAction.Cancel;
	ElsIf CurrentRow.LineKind = 2
		Or CurrentRow.LineKind = 3
		Or CurrentRow.ReceiptIssue = PredefinedValue("Enum.CashFlowTypes.Inpayment")
		Or CurrentRow.TotalsLine Then
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	HyphenationString = Object.PaymentTree.FindByID(String);
	PaymentDate = '00010101';
	ColumnName = New Structure("FieldName", Field.Name);
	Day = Days.FindRows(ColumnName);
	LongTermPeriod = LongTermPeriods.FindRows(ColumnName);
	
	If Day.Count() = 1 Then
		PaymentDate = Day[0].Date;
	ElsIf LongTermPeriod.Count() = 1 Then
		PaymentDate = LongTermPeriod[0].StartDate;
	EndIf;
	
	If ValueIsFilled(PaymentDate) Then
		TransferPaymentItemsClient(DragParameters.Value, PaymentDate, HyphenationString.BankAccountCashAccount);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentRequests

&AtClient
Procedure PaymentRequestsDragStart(Item, DragParameters, Perform)
	
	MarkedEntriesStartDragging(Item, DragParameters, Perform);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Setting(Command)
	
	OpenForm("DataProcessor.CashForecast.Form.Settings",
		New Structure("Object", Object),
		,,,,
		New CallbackDescription("OnSettingsChange", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangeTheMode(Command)
	
	NewMode = MatchingCommandsAndDisplayModes[Command.Name];
	ApplicationMode = (NewMode = "ApplicationsCalendar" And ViewMode = "RequestList")
		Or (NewMode = "RequestList" And ViewMode = "ApplicationsCalendar");
	
	Items.ApplicationsAmountDueFrozenPayments.Check = FrozenPayments;
	Items.FrozenPayments.Check = FrozenPayments;
	
	If ViewMode <> NewMode Then
		ViewMode = NewMode;
		
		If Not ApplicationMode Then
			ClearFlaggedEntries();
		EndIf;
			
		ChangeServerMode();
		SelectionOfApplicationsWhenChangingOnServer();
		ManagingHistoryElements();
		
		ConfigureDisplayOfDimensions();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeServerMode()
	
	If ViewMode = "CalendarPayments" Then
		CurrentListName = "PaymentsInTheCalendar";
		NameOfCurrentListOfTaggedEntries = "TaggedPaymentEntriesInCalendar";
	ElsIf ViewMode = "ApplicationsCalendar" Or ViewMode = "RequestList" Then
		CurrentListName = "PaymentRequests";
		NameOfCurrentListOfTaggedEntries = "MarkedEntriesOfAmountDueRequest";
	EndIf;
	
	If ViewMode <> "ListOfApplicationsAndCalendar" And Object.CalendarAccountFilter = 2 Then
		Object.CalendarAccountFilter = 0;
		Object.FilterBankAccountsCashAccounts.Clear();
		MarkInvoiceFilter();
	EndIf;
	
	If ViewMode <> "RequestList" Then
		UpdateListsOnServer();
	EndIf;
	
	If ViewMode = "InCalendar" Then
		FilterBankAccountCashAccountPresentation = FilterPresentation(Object.FilterBankAccountsCashAccounts);
	EndIf;
	
	ChangeFormItemsVisibility();
	
EndProcedure

&AtClient
Procedure AccountFilterAll(Command)
	
	Object.CalendarAccountFilter = 0;
	Object.FilterBankAccountsCashAccounts.Clear();
	
	UpdatedList_4();
	
EndProcedure

&AtClient
Procedure AccountFilterSelected(Command)
	
	OpenBankAccountSettingsForm();
	
EndProcedure

&AtClient
Procedure AccountFilterSuitable(Command)
	
	Object.CalendarAccountFilter = 2;
	Object.FilterBankAccountsCashAccounts.Clear();
	UpdatedList_4();
	
EndProcedure

&AtClient
Procedure OpenDocument(Command)
	
	OpenPaymentObject();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdatedList_4();
	
EndProcedure

&AtClient
Procedure CancelOperation(Command)
	
	CurrentHistoryIndex = CurrentHistoryIndex - 1;
	CancelRepeatOperation(0);
	
EndProcedure

&AtClient
Procedure RepeatOperation(Command)
	
	CurrentHistoryIndex = CurrentHistoryIndex + 1;
	CancelRepeatOperation(-1);
	
EndProcedure

&AtClient
Procedure CancelRepeatOperation(Move)
	
	IndexOf = CurrentHistoryIndex + Move;
	
	If Not (IndexOf >= 0 And IndexOf < ChangeHistory.Count()) Then
		Return;
	EndIf;
	
	Changes = ChangeHistory.Get(IndexOf).Value;
	
	For Each Update In Changes Do
		If TypeOf(Update.Key) = Type("DocumentRef.PaymentRequest") Then
			For Each ChangeElement_ In Update.Value Do
				ChangeElement_.ZoomRatio = -ChangeElement_.ZoomRatio;
			EndDo;
		Else
			If Update.Value.Count() = 2 Then
				
				BeforeChangeBankAccountCashAccount = Update.Value[0].BankAccountCashAccount;
				PaymentDateBeforeChange = Update.Value[0].PaymentDate;
				
				Update.Value[0].BankAccountCashAccount = Update.Value[1].BankAccountCashAccount;
				Update.Value[0].PaymentDate = Update.Value[1].PaymentDate;
				
				Update.Value[1].BankAccountCashAccount = BeforeChangeBankAccountCashAccount;
				Update.Value[1].PaymentDate = PaymentDateBeforeChange;
			EndIf;
		EndIf;
	EndDo;
	
	TimeConsumingOperation = CancelRepeatOperationOnServer(Changes);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("WhenCompletingUndoRedoOperation", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure PaymentList(Command)
	
	FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen, ReportOptionsCommandsVisibility");
	FormParameters.GenerateOnOpen = True;
	FormParameters.ReportOptionsCommandsVisibility = True;
	
	FormParameters.PurposeUseKey = "PaymentList";
	FormParameters.VariantKey = "PaymentList";
	
	Filter = New Structure;
	PaymentDate = CashClientServer.PaymentDate(Object.PlanFromDate, Object.PlanningDays);
	Filter.Insert("Period", New StandardPeriod(Object.PlanFromDate, PaymentDate));
	
	If ValueIsFilled(FilterCompaniesPresentation) Then
		Companies = New Array;
		For Each FilterElement In Object.FilterCompanies Do
			If FilterElement.Check Then
				Companies.Add(FilterElement.Value);
			EndIf;
		EndDo;
		Filter.Insert("Organization", Companies);
	EndIf;
	
	If ValueIsFilled(FilterBankAccountCashAccountPresentation) Then
		BankAccountsCashAccounts = New Array;
		For Each FilterElement In Object.FilterBankAccountsCashAccounts Do
			If FilterElement.Check Then
				BankAccountsCashAccounts.Add(FilterElement.Value);
			EndIf;
		EndDo;
		Filter.Insert("BankAccountCashAccount", BankAccountsCashAccounts);
	EndIf;
	
	Filter.Insert("TotalCurrency", Object.TotalCurrency);
	
	If FilterPlanningAreas.Count() Then
		Filter.Insert("PlanningArea", FilterPlanningAreas);
	EndIf;
	
	If ValueIsFilled(Object.FilterCurrency) Then
		Filter.Insert("Currency", Object.FilterCurrency);
	EndIf;
	
	FormParameters.Filter = Filter;
	
	OpenForm("Report.PaymentList.Form", FormParameters, ThisObject, New UUID);
	
EndProcedure

&AtClient
Procedure SwitchZoomModeOfView(Command)
	
	Items.SwitchZoomModeOfView.Check = Not Items.SwitchZoomModeOfView.Check;
	CompactMode = Items.SwitchZoomModeOfView.Check;
	Scale = ?(CompactMode, CompactModeScale(), 100);
	
EndProcedure

&AtClient
Procedure AdvancedFilter(Command)
	
	OpeningParameters = ParametersOfExtendedSelectionForm();
	
	CloseHandler = New CallbackDescription("SetAdvancedSelectionCompletion", ThisObject);
	OpenForm("DataProcessor.CashForecast.Form.AdvancedFilter", OpeningParameters, ThisObject, , , ,
		CloseHandler, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	CheckBoxesOnServer();
	CommonClientServer.SetDynamicListParameter(ThisObject[CurrentListName], "TaggedEntries",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
	
	CurFormList = Items[CurrentListName]; // FormTable
	CurFormList.Refresh();
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	ClearFlaggedEntries();
	CommonClientServer.SetDynamicListParameter(ThisObject[CurrentListName], "TaggedEntries",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
	
	CurFormList = Items[CurrentListName]; // FormTable
	CurFormList.Refresh();
	
EndProcedure

#Region ListView

&AtClient
Procedure ApplicationsToDistribution(Command)
	
	Items.ApplicationsToDistribution.Check = Not Items.ApplicationsToDistribution.Check;
	
	PickRequests = Items.ApplicationsToDistribution.Check;
	SelectionOfApplicationsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ToChangeTheGroupingOfPayments(Command)
	
	ToChangeTheGroupingOfPaymentsServer(Command.Name);
	
EndProcedure

&AtServer
Procedure ToChangeTheGroupingOfPaymentsServer(CommandName)
	
	GroupName = "";
	Keyword = StrReplace("GroupingSection", "Section", "");
	If StrStartsWith(CommandName, Keyword) Then
		GroupName = Right(CommandName, StrLen(CommandName) - StrLen(Keyword));
		GroupName = StrReplace(GroupName, "_", "");
	EndIf;
	
	UserSettings = ThisForm[CurrentListName].SettingsComposer.UserSettings; // DataCompositionUserSettings 
	
	SettingUpAGrouping = UserSettings.Items[3];
	SettingUpAGrouping.Structure.Clear();
	
	If ValueIsFilled(GroupName) Then
		Field = New DataCompositionField(GroupName);
		NewGrouping = SettingUpAGrouping.Structure.Add(Type("DataCompositionGroup")); // DataCompositionGroup
		GroupingField = NewGrouping.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Field = Field;
	EndIf;
	
	MarkListGrouping(GroupName);
	
EndProcedure

#EndRegion

#Region InteractiveActions

&AtClient
Procedure Allocate(Command)
	
	ClearMessages();
	
	If ThisObject[NameOfCurrentListOfTaggedEntries].Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có khoản thanh toán nào được chọn.';
										|ru = 'Не отмечено ни одного платежа.';
										|en = 'No payment is selected.'; fa = 'No payment is selected.';
										|it = 'No payment is selected.';
										|pl = 'No payment is selected.';
										|tr = 'Hiçbir ödeme işaretlenmemiş.'"));
		Return;
	EndIf;
	
	TimeConsumingOperation = DistributeAtServer(ThisObject[NameOfCurrentListOfTaggedEntries]);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AtEndOfTransferOfPaymentObjects", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure RightShift(Command)
	
	MovePaymentObjects("ToRight");
	
EndProcedure

&AtClient
Procedure TheShiftInTheEnd(Command)
	
	MovePaymentObjects("ToEnd");
	
EndProcedure

&AtClient
Procedure LeftShift_3(Command)
	
	MovePaymentObjects("ToLeft");
	
EndProcedure

&AtClient
Procedure ShiftToTheBeginning_3(Command)
	
	MovePaymentObjects("ToBeginning");
	
EndProcedure

&AtClient
Procedure ShiftOnTheDate(Command)
	
	MovePaymentObjects("OnDate");
	
EndProcedure

&AtClient
Procedure AccountShift(Command)
	
	MovePaymentObjects("ToAccount");
	
EndProcedure

&AtClient
Procedure SplitShift(Command)
	
	MovePaymentObjects("Split");
	
EndProcedure

&AtClient
Procedure TheShearIsNotDistributed(Command)
	
	MovePaymentObjects("NotAllocated");
	
EndProcedure

&AtClient
Procedure CloseApplications(Command)
	
	If ThisObject[NameOfCurrentListOfTaggedEntries].Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có khoản thanh toán nào được chọn.';
										|ru = 'Не отмечено ни одного платежа.';
										|en = 'No payment is selected.'; fa = 'No payment is selected.';
										|it = 'No payment is selected.';
										|pl = 'No payment is selected.';
										|tr = 'Hiçbir ödeme işaretlenmemiş.'"));
		Return;
	EndIf;
	
	ClearMessages();
	
	TransferPaymentItemsClient(ThisObject[NameOfCurrentListOfTaggedEntries], Date("00010101"), Null, True);
	
EndProcedure

&AtClient
Procedure FrozenPayments(Command)
	
	If ViewMode = "CalendarPayments" Then
	
		Items.FrozenPayments.Check = Not Items.FrozenPayments.Check;
		FrozenPayments = Items.FrozenPayments.Check;
		
		SetCalendarPaymentsSelectionAtServer();
	
	ElsIf ViewMode = "ApplicationsCalendar" Or ViewMode = "RequestList" Then
		
		Items.ApplicationsAmountDueFrozenPayments.Check = Not Items.ApplicationsAmountDueFrozenPayments.Check;
		FrozenPayments = Items.ApplicationsAmountDueFrozenPayments.Check;
		
		CommonClientServer.SetDynamicListFilterItem(PaymentRequests, "Frozen",
			FrozenPayments);
	EndIf;
	
EndProcedure

&AtClient
Procedure FreezeMarkedPayments(Command)
	
	If ThisObject[NameOfCurrentListOfTaggedEntries].Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	TimeConsumingOperation = FreezeMarkedPaymentsATServer();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AtEndFreezeReturnToExecution", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure ReturnForExecution(Command)
	
	If ThisObject[NameOfCurrentListOfTaggedEntries].Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	CountOfPayments = NumberOfPaymentsToFreezeAndRefundForExecution(True);
	
	If CountOfPayments = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có khoản thanh toán bị đóng băng nào được chọn.';
										|ru = 'Не отмечено ни одного замороженного платежа.';
										|en = 'No frozen payment is selected.'; fa = 'No frozen payment is selected.';
										|it = 'No frozen payment is selected.';
										|pl = 'No frozen payment is selected.';
										|tr = 'Hiçbir dondurulmuş ödeme işaretlenmemiş.'"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("EnteringDateToReturnToExecutionEnd", ThisObject);
	ToolTipText = NStr("vi = 'Vui lòng chọn ngày để đưa trở lại thực hiện.';
						|ru = 'Выберите дату для возврата на исполнение.';
						|en = 'Select a date to return for execution.'; fa = 'Select a date to return for execution.';
						|it = 'Select a date to return for execution.';
						|pl = 'Select a date to return for execution.';
						|tr = 'İcraya iade için tarih seçin.'");
		
	ShowInputDate(CallbackDescription, Object.PlanFromDate, ToolTipText, DateFractions.Date);
	
EndProcedure

&AtClient
Procedure FreezeOverduePayments(Command)
	
	CallbackDescription = New CallbackDescription("EnteringDepthOfDelayEnd", ThisObject);
	ToolTipText = NStr("vi = 'Khoảng thời gian quá hạn (ngày).';
						|ru = 'Глубина просрочки (дней).';
						|en = 'Days past due'; fa = 'روزهای سررسید گذشته';
						|it = 'Days past due';
						|pl = 'Days past due';
						|tr = 'Gecikme süresi (gün).'");
		
	ShowInputNumber(CallbackDescription, 10, ToolTipText, 4, 0);
	
EndProcedure

&AtClient
Procedure PaymentRequests(Command)
	
	ClearMessages();
	
	If ThisObject[NameOfCurrentListOfTaggedEntries].Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có khoản thanh toán nào được chọn.';
										|ru = 'Не отмечено ни одного платежа.';
										|en = 'No payment is selected.'; fa = 'No payment is selected.';
										|it = 'No payment is selected.';
										|pl = 'No payment is selected.';
										|tr = 'Hiçbir ödeme işaretlenmemiş.'"));
		Return;
	EndIf;
	
	Requests = AmountDueATServer();
	
	If Requests.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(Requests, "AmountDue");
	CurFormList = Items[CurrentListName]; // FormTable

	TMCommonUseClient.NotifyUserAboutSettingStatus(CurFormList, ProcessedItemsCount,
		Requests.Count(), "AmountDue");
	ClearFlaggedEntries();
	CommonClientServer.SetDynamicListParameter(PaymentsInTheCalendar, "TaggedEntries",
		TaggedPaymentEntriesInCalendar);
	UpdateListsOnServer();
	CurFormList.Refresh();
	
EndProcedure

&AtClient
Procedure RejectRequests(Command)
	
	ClearMessages();
	
	If ThisObject[NameOfCurrentListOfTaggedEntries].Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có khoản thanh toán nào được chọn.';
										|ru = 'Не отмечено ни одного платежа.';
										|en = 'No payment is selected.'; fa = 'No payment is selected.';
										|it = 'No payment is selected.';
										|pl = 'No payment is selected.';
										|tr = 'Hiçbir ödeme işaretlenmemiş.'"));
		Return;
	EndIf;
	
	Requests = RejectRequestsATServer();
	
	If Requests.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(Requests, "IsRejected");
	CurFormList = Items[CurrentListName]; // FormTable

	TMCommonUseClient.NotifyUserAboutSettingStatus(CurFormList, ProcessedItemsCount,
		Requests.Count(), "IsRejected");
	ClearFlaggedEntries();
	CommonClientServer.SetDynamicListParameter(PaymentsInTheCalendar, "TaggedEntries",
		TaggedPaymentEntriesInCalendar);
	CurFormList.Refresh();
	
EndProcedure

#EndRegion

#Region PaymentTree

&AtClient
Procedure ShiftUp(Command)
	
	If Not LineCanBeShifted(-1) Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng hiện tại.';
								|ru = 'Команда не может быть выполнена для текущей строки.';
								|en = 'Command cannot be executed for the current line.'; fa = 'Command cannot be executed for the current line.';
								|it = 'Il comando non può essere eseguito per la riga selezionato.';
								|pl = 'Komenda nie może być wykonana dla bieżącego wiersza.';
								|tr = 'Mevcut satır için komut gerçekleştirilemez'"));
		Return;
	EndIf;
	
	ShiftLine(-1);
	
EndProcedure

&AtClient
Procedure ShiftDown(Command)
	
	If Not LineCanBeShifted(1) Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng hiện tại.';
								|ru = 'Команда не может быть выполнена для текущей строки.';
								|en = 'Command cannot be executed for the current line.'; fa = 'Command cannot be executed for the current line.';
								|it = 'Il comando non può essere eseguito per la riga selezionato.';
								|pl = 'Komenda nie może być wykonana dla bieżącego wiersza.';
								|tr = 'Mevcut satır için komut gerçekleştirilemez'"));
		Return;
	EndIf;
	
	ShiftLine(1);
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	TreeItems = Object.PaymentTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items.PaymentTree.Collapse(TreeItem.GetID());
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	TreeItems = Object.PaymentTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items.PaymentTree.Expand(TreeItem.GetID(), True);
	EndDo;
	
EndProcedure

#EndRegion

#Region CreatingDocuments

&AtClient
Procedure CreateExpectedReceipt(Command)
	
	StructureFilter = New Structure;
	
	CurrentData = Items.PaymentTree.CurrentData;
	If CurrentData <> Undefined Then
		
		If ValueIsFilled(CurrentTreeColumn) Then
			If CurrentTreeColumn <> "PaymentTreeBalance"
				And CurrentTreeColumn <> "PaymentTreeStretching" Then
				
				CurrentCalendarDate = AllocatedDay(CurrentTreeColumn, Object.PlanFromDate);
				If ValueIsFilled(CurrentCalendarDate) Then
					StructureFilter.Insert("Date", CurrentCalendarDate);
				EndIf;
			EndIf;
		EndIf;
		
		BankAccountCashAccount = CurrentData.BankAccountCashAccount;
		
		If ValueIsFilled(BankAccountCashAccount) Then
			If TypeOf(BankAccountCashAccount) = Type("CatalogRef.CompaniesBankAccounts") Then
				StructureFilter.Insert("PaymentMethod", PredefinedValue("Enum.PaymentForms.BankAccountPayment"));
				StructureFilter.Insert("BankAccount", BankAccountCashAccount);
			ElsIf TypeOf(CurrentData.BankAccountCashAccount) = Type("CatalogRef.CashAccounts") Then
				StructureFilter.Insert("PaymentMethod", PredefinedValue("Enum.PaymentForms.CashAccountPayment_"));
				StructureFilter.Insert("CashAccount", BankAccountCashAccount);
			EndIf;
			
			AttributesNames = "Owner, CashCurrency";
			Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(CurrentData.BankAccountCashAccount, AttributesNames);
			StructureFilter.Insert("Organization", Attributes.Owner);
			StructureFilter.Insert("Currency", Attributes.CashCurrency);
		EndIf;
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", StructureFilter);
	OpenForm("Document.PlannedCashReceipt.ObjectForm", ParametersStructure1, ThisForm);
	
EndProcedure

&AtClient
Procedure CreateATransferOrder(Command)
	
	CommandName = Command.Name;
	
	If CommandName = "CreateTransferToAnotherAccount" Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferCashToAnotherAccount");
	ElsIf CommandName = "CreateIssuanceToAnotherCashAccount" Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashIssueToAnotherCashAccount");
	ElsIf CommandName = "CreateCashCollectionToTheBank" Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashCollectionToBank");
	ElsIf CommandName = "CreateCashCollectionToCashAccount" Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WithdrawalFromBankAccount");
	EndIf;
	
	StructureFilter = New Structure;
	StructureFilter.Insert("BusinessOperation", BusinessOperation);
	
	CurrentData = Items.PaymentTree.CurrentData;
	If CurrentData <> Undefined Then
		
		BankAccountCashAccount = CurrentData.BankAccountCashAccount;
		
		If ValueIsFilled(BankAccountCashAccount) Then
			StructureFilter.Insert("BankAccount", BankAccountCashAccount);
			StructureFilter.Insert("CashAccount", BankAccountCashAccount);
		
			AttributesNames = "Owner, CashCurrency";
			Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(CurrentData.BankAccountCashAccount, AttributesNames);
			StructureFilter.Insert("Organization", Attributes.Owner);
			StructureFilter.Insert("Currency", Attributes.CashCurrency);
		EndIf;
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", StructureFilter);
	OpenForm("Document.CashTransferReferenceOrder.ObjectForm", ParametersStructure1, ThisForm);
	
EndProcedure

&AtClient
Procedure CreateAConversionRequest(Command)
	
	StructureFilter = New Structure;
	StructureFilter.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.CurrencyConversion"));
	
	CurrentData = Items.PaymentTree.CurrentData;
	If CurrentData <> Undefined Then
		
		BankAccountCashAccount = CurrentData.BankAccountCashAccount;
		
		If ValueIsFilled(BankAccountCashAccount) Then
			If TypeOf(BankAccountCashAccount) = Type("CatalogRef.CompaniesBankAccounts") Then
				StructureFilter.Insert("PaymentMethodBankAccount", True);
				StructureFilter.Insert("PaymentMethodCash", False);
				StructureFilter.Insert("MethodOfPaymentPaymentCard", False);
				StructureFilter.Insert("PaymentMethodOfPaymentRequest", PredefinedValue("Enum.PaymentForms.BankAccountPayment"));
			ElsIf TypeOf(CurrentData.BankAccountCashAccount) = Type("CatalogRef.CashAccounts") Then
				StructureFilter.Insert("PaymentMethodBankAccount", False);
				StructureFilter.Insert("PaymentMethodCash", True);
				StructureFilter.Insert("MethodOfPaymentPaymentCard", False);
				StructureFilter.Insert("PaymentMethodOfPaymentRequest", PredefinedValue("Enum.PaymentForms.CashAccountPayment_"));
			EndIf;
			
			AttributesNames = "Owner, CashCurrency";
			Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(CurrentData.BankAccountCashAccount, AttributesNames);
			StructureFilter.Insert("Organization", Attributes.Owner);
			StructureFilter.Insert("CurrencyOfConversion", Attributes.CashCurrency);
		EndIf;
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", StructureFilter);
	OpenForm("Document.PaymentRequest.ObjectForm", ParametersStructure1, ThisForm);
	
EndProcedure

&AtClient
Procedure GenerateWriteOffsForTheVehicle(Command)
	
	ClearMessages();
	Result = GenerateCashDebitsOnServer();
	If Result <> Undefined Then
		CashClient.OpenPaymentResultsForChartLines(Items[CurrentListName], Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreatePaymentRequests(Command)
	
	ClearMessages();
	
	Result = CreateCashPaymentRequestsAtServer();
	If Result <> Undefined Then
		CashClient.OpenPaymentResultsForChartLines(Items.PaymentsInTheCalendar, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateCashVoucher(Command)
	
	ClearMessages();
	
	Result = CreateACWATServer();
	If Result <> Undefined Then
		CashClient.OpenPaymentResultsForChartLines(Items.PaymentsInTheCalendar, Result);
	EndIf;
	
EndProcedure

&AtServer
Function GenerateCashDebitsOnServer()
	
	LineUp = AlignmentOfCurrentList(Items[CurrentListName]);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;
	
	SelectedFields = New Array;
	SelectedFields.Add("PaymentObject");
	SelectedFields.Add("BankAccountCashAccount");
	SelectedFields.Add("PaymentDate");
	SelectedFields.Add("PayerBeneficiary");
	SelectedFields.Add("Organization");
	SelectedFields.Add("ReceiptIssue");
	SelectedFields.Add("Currency");
	SelectedFields.Add("Id");
	
	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup")); // DataCompositionGroup
	For Each SelectedField In SelectedFields Do
		DetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField")).Field = New DataCompositionField(SelectedField);
	EndDo;
	
	StatusesPayable = New Array;
	StatusesPayable.Add(Enums.StatusesOfPaymentRequests.AmountDue);
	StatusesPayable.Add(Enums.CashTransferOrderStatuses.AmountDue);
	StatusesPayable.Add(Enums.EmployeeApplicationStatuses.AgreedUpon);
	
	FinancialReportingServer.SetFilter(
		Settings.Filter,
		"RequestStatus_",
		StatusesPayable);
		
	FinancialReportingServer.SetFilter(
		Settings.Filter,
		"PaymentMethod",
		Enums.PaymentForms.CashAccountPayment_,
		DataCompositionComparisonType.NotEqual);
		
	FinancialReportingServer.SetFilter(
		Settings.Filter,
		"Id",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
		
	GroundsForWriteOffs = FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
	If GroundsForWriteOffs.Count() Then
		Return CashServer.PayChartLines(GroundsForWriteOffs, "BankAccountIssue",
					Object.GroupDocumentsWhenCreating);
	Else
		Common.MessageToUser(
			NStr("vi = 'Trong danh sách không có chứng từ cần thanh toán để tạo các chứng từ ghi giảm.';
				|ru = 'В списке нет документов к оплате для формирования документов списания.';
				|en = 'There are no documents for payment for cash outflow document generation in the list.'; fa = 'There are no documents for payment for cash outflow document generation in the list.';
				|it = 'There are no documents for payment for cash outflow document generation in the list.';
				|pl = 'There are no documents for payment for cash outflow document generation in the list.';
				|tr = 'Listede, gider yazma belgeleri oluşturmak için ödeme belgeleri mevcut değil.'"));
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region PlugIns

&AtClient
Procedure Attachable_ShowGroupsLevel(Command)

	TheLevelOfGroupingByAString = StrReplace(Command.Name, Items.ShowGroupsLevel.Name, "");

	NumberDetails = New TypeDescription("Number");
	GroupingLevel = NumberDetails.AdjustValue(TheLevelOfGroupingByAString);

	ShowTheSelectedGroupingLevel(GroupingLevel);

EndProcedure

#EndRegion

#EndRegion

#Region EventHandlersForHeaderElements

&AtClient
Procedure PlanningDaysOnChange(Item)
	
	AttachIdleHandler("WhenPlanningDaysChange", 0.1, True);
	
EndProcedure

&AtClient
Procedure WhenPlanningDaysChange()
	
	WhenYouChangeSchedulingDaysOnServer();
	
EndProcedure

&AtServer
Procedure WhenYouChangeSchedulingDaysOnServer()
	
	DataProcessors.CashForecast.FillInEndDates(Object);
	
	UpdateListsOnServer();
	AddDaysColumns();
	AddLongTermPlanningColumns();
	
	If ViewMode <> "RequestList" Then
		ChangeVisibilityOfPlanningDays();
	EndIf;
	
	If ViewMode <> "CalendarPayments" Then
		SetDynamicListSelections();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterCompaniesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ClosingNotification1 = New CallbackDescription("SelectionOfSelectionOrganizations", ThisObject);
	
	Marked = New ValueList;
	For Each OrganizationElement In Object.FilterCompanies Do
		If OrganizationElement.Check Then
			Marked.Add(OrganizationElement.Value,, True);
		EndIf;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("RestrictSelectionBySpecifiedValues", True);
	FormParameters.Insert("Presentation", NStr("vi = 'Lựa chọn doanh nghiệp';
												|ru = 'Отбор организаций';
												|en = 'Company filter'; fa = 'فیلتر شرکت';
												|it = 'Selezione aziende';
												|pl = 'Filtr firm';
												|tr = 'İş yerlerini filtrele'"));
	FormParameters.Insert("ValuesForSelection", Object.FilterCompanies);
	FormParameters.Insert("TypeDescription", FilterCompanies.ValueType);
	FormParameters.Insert("Marked", Marked);
	
	OpenForm("CommonForm.InputValuesInListWithCheckBoxes", FormParameters, ThisObject,,,,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionOfSelectionOrganizations(Result, AdditionalParameters) Export
	
	If Result <> Undefined And TypeOf(Result) = Type("ValueList") Then
		Object.FilterCompanies = Result;
		FilterCompaniesPresentation = FilterPresentation(Object.FilterCompanies);
		InstallComposerSelectionByCompanySelection(Object.LinkerSelection, Object.FilterCompanies);
		UpdatedList_4();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterCompaniesClearing(Item, StandardProcessing)
	
	Object.FilterCompanies.FillChecks(False);
	InstallComposerSelectionByCompanySelection(Object.LinkerSelection, Object.FilterCompanies);
	UpdatedList_4();
	
EndProcedure

&AtClient
Procedure FilterCompaniesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectedOrganizationElement = Object.FilterCompanies.FindByValue(ValueSelected);
	If SelectedOrganizationElement <> Undefined Then
		Object.FilterCompanies.FillChecks(False);
		SelectedOrganizationElement.Check = True;
		InstallComposerSelectionByCompanySelection(Object.LinkerSelection, Object.FilterCompanies);
		UpdatedList_4();
	EndIf;
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure PaymentRequestsOnActivateRow(Item)
	
	If ViewMode = "ApplicationsCalendar" Then
		
		If Object.CalendarAccountFilter = 2 Then
			
			CurrentListLine = Items.PaymentRequests.CurrentRow;
			
			If ValueIsFilled(CurrentListLine) And TypeOf(CurrentListLine) <> Type("DynamicListGroupRow") Then
				CurrentRequest = Items.PaymentRequests.CurrentData.PaymentObject;
				Items.PaymentPanelGroup.CurrentPage = Items.PagePopulation;
				AttachIdleHandler("StartFillingWhenActivatingListOfApplications", 0.1, True);
			Else
				CurrentRequest = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentTreeOnActivateCell(Item)
	
	If ViewMode <> "RequestList" And Not CalendarCellActivationOnDraggingIsDisabled Then
		
		CurTreeElement = Item.CurrentItem; // FormField
		
		If CurTreeElement <> Undefined Then
			
			If (ViewMode = "CalendarPayments") And (CurrentTreeColumn <> CurTreeElement.Name) Then
				ClearFlaggedEntries();
			EndIf;
			
			CurrentTreeRow = Item.CurrentRow;
			CurrentTreeColumn = Item.CurrentItem.Name;
			
			CurrentData = Item.CurrentData;
			If CurrentData <> Undefined Then
				
				TextCriticalBalance = NStr("vi = 'Số dư tiền mặt thấp hơn mức giới hạn %1.';
											|ru = 'Остаток денежных средств ниже критической суммы %1.';
											|en = 'Cash balance is below the critical amount (%1).'; fa = 'Cash balance is below the critical amount (%1).';
											|it = 'Cash balance is below the critical amount (%1).';
											|pl = 'Cash balance is below the critical amount (%1).';
											|tr = 'Nakit bakiyesi, kritik tutar olan %1’in altında.'");
				TextApplicationWasNotCreated = NStr("vi = 'Để thực hiện thanh toán, cần lập giấy đề nghị chi tiền.';
													|ru = 'Для оплаты требуется оформить заявку на расходование денежных средств.';
													|en = 'To make a payment, register a payment request.'; fa = 'To make a payment, register a payment request.';
													|it = 'To make a payment, register a payment request.';
													|pl = 'To make a payment, register a payment request.';
													|tr = 'Ödeme için ödeme talebi oluşturulması gerekiyor.'");
				TextOriginalPaymentDateIsLessThanRescheduledOne =
					NStr("vi = 'Khoản thanh toán đã được chuyển sang ngày muộn hơn so với ngày đã thiết lập trong chứng từ.';
						|ru = 'Платеж перенесен на дату позже, даты установленной в документе.';
						|en = 'The payment is postponed to a date later than the date specified in the document.'; fa = 'The payment is postponed to a date later than the date specified in the document.';
						|it = 'The payment is postponed to a date later than the date specified in the document.';
						|pl = 'The payment is postponed to a date later than the date specified in the document.';
						|tr = 'Ödeme, belgede belirlenen tarihten ileri bir tarihe taşınmıştır.'");
				ErrorTextOfCurrentCell = "";
				ErrorsTexts = New Array;
				
				If Not (  CurrentTreeGrouping   = CurrentData.Group
						 And CurrentBankAccountCashAccount = CurrentData.BankAccountCashAccount
						 And CurrentCurrency			  = CurrentData.Currency)
					And (ViewMode = "CalendarPayments") Then
					ClearFlaggedEntries();
				EndIf;
				
				CurrentTreeGrouping		  = CurrentData.Group;
				CurRowOfTreeIsNotDistributed = CurrentData.UnallocatedLine;
				CurRowOfTreeIsDistributed	  = CurrentData.StringIsDistributed;
				CurrentBankAccountCashAccount		  = CurrentData.BankAccountCashAccount;
				CurrentCurrency					  = CurrentData.Currency;
				CurrentLineKind				  = CurrentData.LineKind;
				CurrentMovementType				  = CurrentData.ReceiptIssue;
				CurrentCompany				  = CurrentData.Organization;
				CurrentTypeOfFunds		  = CurrentData.CashType;
				CurBank						  = CurrentData.CashAccountBank;
				
				BankAccountPayments_ = PredefinedValue("Enum.CashTypes.BankAccountPayments_");
				CashPayment = PredefinedValue("Enum.CashTypes.CashPayment");
				
				If CurrentTreeColumn <> "PaymentTreeIrreducibleBalance"
					And StrFind(CurrentTreeColumn, "Balance") > 0 Then
					If CurrentData.BalanceErrorCriticalBalance Then
						If CurrentTypeOfFunds = BankAccountPayments_ Then
							ErrorsTexts.Add(StrTemplate(TextCriticalBalance, NStr("vi = 'tài khoản ngân hàng';
																					|ru = 'банковского счета';
																					|en = 'bank account'; fa = 'bank account';
																					|it = 'bank account';
																					|pl = 'bank account';
																					|tr = 'banka hesabı'")));
						ElsIf CurrentTypeOfFunds = CashPayment Then
							ErrorsTexts.Add(StrTemplate(TextCriticalBalance, NStr("vi = 'quỹ tiền mặt';
																					|ru = 'кассы';
																					|en = 'cash account'; fa = 'cash account';
																					|it = 'cash account';
																					|pl = 'cash account';
																					|tr = 'kasa hesabı'")));
						EndIf;
					EndIf;
				
				ElsIf StrFind(CurrentTreeColumn, "Day") > 0
					Or StrFind(CurrentTreeColumn, "LongTermPeriod") > 0 Then
					ItSDay = (StrFind(CurrentTreeColumn, "Day") > 0);
			
					If ItSDay Then
						Number = DayNumber(CurrentTreeColumn);
						PeriodName = "Day";
					Else
						Number = LongTermPeriodNumber(CurrentTreeColumn);
						PeriodName = "LongTermPeriod";
					EndIf;
			
					If Number > 0 Then
						ThereIsCriticalBalanceError = False;
						ColumnNameErrorCriticalBalance = PeriodName + Number + "ErrorCriticalBalance";
						If CurrentData.Property(ColumnNameErrorCriticalBalance, ThereIsCriticalBalanceError)
							And ThereIsCriticalBalanceError Then
							If CurrentTypeOfFunds = BankAccountPayments_ Then
								ErrorsTexts.Add(StrTemplate(TextCriticalBalance, NStr("vi = 'tài khoản ngân hàng';
																						|ru = 'банковского счета';
																						|en = 'bank account'; fa = 'bank account';
																						|it = 'bank account';
																						|pl = 'bank account';
																						|tr = 'banka hesabı'")));
							ElsIf CurrentTypeOfFunds = CashPayment Then
								ErrorsTexts.Add(StrTemplate(TextCriticalBalance, NStr("vi = 'quỹ tiền mặt';
																						|ru = 'кассы';
																						|en = 'cash account'; fa = 'cash account';
																						|it = 'cash account';
																						|pl = 'cash account';
																						|tr = 'kasa hesabı'")));
							EndIf;
						EndIf;
					EndIf;
					
					ThereIsErrorApplicationWasNotCreated = False;
					ColumnNameThereIsErrorRequestWasNotCreated = PeriodName + Number + "ThereIsErrorApplicationWasNotCreated";
					If CurrentData.Property(ColumnNameThereIsErrorRequestWasNotCreated, ThereIsErrorApplicationWasNotCreated)
						And ThereIsErrorApplicationWasNotCreated Then
						ErrorsTexts.Add(TextApplicationWasNotCreated);
					EndIf;
					
					ThereIsInitialPaymentDateLessThanRescheduledOne = False;
					ColumnNameIsOriginalPaymentDateLessThanRescheduledOne = PeriodName + Number
						+ "ThereIsInitialPaymentDateLessThanRescheduledOne";
					If CurrentData.Property(ColumnNameIsOriginalPaymentDateLessThanRescheduledOne,
						ThereIsInitialPaymentDateLessThanRescheduledOne)
						And ThereIsInitialPaymentDateLessThanRescheduledOne Then
						ErrorsTexts.Add(TextOriginalPaymentDateIsLessThanRescheduledOne);
					EndIf;
				EndIf;
				
				If ErrorsTexts.Count() Then
					ErrorTextOfCurrentCell = StrConcat(ErrorsTexts, " ");
				EndIf;
			Else
				CurrentTreeGrouping = Undefined;
				CurRowOfTreeIsNotDistributed = False;
				CurRowOfTreeIsDistributed = False;
				CurrentBankAccountCashAccount = Undefined;
				CurrentCurrency = Undefined;
				CurrentLineKind = -1;
				CurrentMovementType = Undefined;
				CurrentCompany = Undefined;
				CurrentTypeOfFunds = Undefined;
				CurBank = Undefined;
			EndIf;
		EndIf;
		
		AttachIdleHandler("Attachable_SetSelectionInCalendar", 0.1, True);
	EndIf;
	
	CalendarCellActivationOnDraggingIsDisabled = False;
	
EndProcedure

&AtClient
Procedure PaymentsInTheCalendarSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(RowSelected) <> Type("DynamicListGroupRow") Then
		StandardProcessing = False;
		If Field = Items.PaymentsInTheCalendarCheck Then
			CurrentData = Items.PaymentsInTheCalendar.CurrentData;
			If CurrentData <> Undefined Then
				
				IdCreated = "";
				If Not ValueIsFilled(CurrentData.Id) Then
					
					GraphMeasurements = GraphMeasurements();
					FillPropertyValues(GraphMeasurements, CurrentData);
					IdCreated = FillInIdSourceAttributesInMarkedLine(GraphMeasurements);
				EndIf;
					
				If ValueIsFilled(IdCreated) Or ValueIsFilled(CurrentData.Id) Then
					
					RecordID = ?(ValueIsFilled(CurrentData.Id), CurrentData.Id,
						IdCreated);
					
					If CurrentData.Check Then
						ListItem = TaggedPaymentEntriesInCalendar.FindByValue(RecordID);
						If ListItem <> Undefined Then
							TaggedPaymentEntriesInCalendar.Delete(ListItem);
							Totals_Amount = Totals_Amount - CurrentData.Sum;
							TotalsQuantity = TotalsQuantity - 1;
						EndIf;
					Else
						ListItem = TaggedPaymentEntriesInCalendar.FindByValue(RecordID);
						If ListItem = Undefined Then
							TaggedPaymentEntriesInCalendar.Add(RecordID);
							Totals_Amount = Totals_Amount + CurrentData.Sum;
							TotalsQuantity = TotalsQuantity + 1;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			CommonClientServer.SetDynamicListParameter(PaymentsInTheCalendar, "TaggedEntries",
				TaggedPaymentEntriesInCalendar);
			Items.PaymentsInTheCalendar.Refresh();
		Else
			OpenPaymentObject();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentRequestsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(RowSelected) <> Type("DynamicListGroupRow") Then
		StandardProcessing = False;
		If Field = Items.PaymentRequestsCheck Then
			CurrentData = Items.PaymentRequests.CurrentData;
			If CurrentData <> Undefined Then
				
				IdCreated = "";
				If Not ValueIsFilled(CurrentData.Id) Then
					
					GraphMeasurements = GraphMeasurements();
					FillPropertyValues(GraphMeasurements, CurrentData);
					IdCreated = FillInIdSourceAttributesInMarkedLine(GraphMeasurements);
				EndIf;
				
				If ValueIsFilled(IdCreated) Or ValueIsFilled(CurrentData.Id) Then
					
					RecordID = ?(ValueIsFilled(CurrentData.Id), CurrentData.Id,
						IdCreated);
				
					If CurrentData.Check Then
						ListItem = MarkedEntriesOfAmountDueRequest.FindByValue(RecordID);
						If ListItem <> Undefined Then
							MarkedEntriesOfAmountDueRequest.Delete(ListItem);
							Totals_Amount = Totals_Amount - CurrentData.Sum;
							TotalsQuantity = TotalsQuantity - 1;
						EndIf;
					Else
						ListItem = MarkedEntriesOfAmountDueRequest.FindByValue(RecordID);
						If ListItem = Undefined Then
							MarkedEntriesOfAmountDueRequest.Add(RecordID);
							Totals_Amount = Totals_Amount + CurrentData.Sum;
							TotalsQuantity = TotalsQuantity + 1;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			CommonClientServer.SetDynamicListParameter(PaymentRequests, "TaggedEntries",
				MarkedEntriesOfAmountDueRequest);
			Items.PaymentRequests.Refresh();
		Else
			OpenPaymentObject();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region FormDesign

&AtServer
Procedure SetConditionalAppearance()
	
	PaymentTreePath = "Object.PaymentTree";
	ConditionalAppearance.Items.Clear();
	
	// Negative balance
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTree.Name);
	
	TypesOfString = New ValueList;
	TypesOfString.Add(0);
	TypesOfString.Add(2);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".LineKind",
		TypesOfString);
	
	Item.Appearance.SetParameterValue("MarkNegatives", True);
	
	// Font of results
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTreeGroup.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTreeCurrency.Name);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".UnallocatedLine", True);
	
	Item.Appearance.SetParameterValue("Font", New Font(ThisForm.Items.PaymentTree.Font,,, True));
	
	// Background of the results
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTree.Name);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".TotalsLine", True);
	
	Item.Appearance.SetParameterValue("BackColor", New Color(242, 242, 242));
	
	// Currency visibility
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTreeCurrency.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FinancialReportingServer.SetFilter(FilterGroup2, PaymentTreePath + ".LineKind", 1);
	
	FinancialReportingServer.SetFilter(FilterGroup2, PaymentTreePath + ".Group",
		"allocated", DataCompositionComparisonType.NotContains);
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	TypesOfString = New ValueList;
	TypesOfString.Add(2);
	TypesOfString.Add(3);
	
	FinancialReportingServer.SetFilter(FilterGroup3, PaymentTreePath + ".LineKind", TypesOfString);
	
	FinancialReportingServer.SetFilter(FilterGroup3, PaymentTreePath + ".Group",
		"InTotal", DataCompositionComparisonType.NotContains);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// Payment date of overdue applications
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentRequestsPaymentDate.Name);
	
	FinancialReportingServer.SetFilter(Item.Filter, "PaymentRequests.PaymentDate",
		New DataCompositionField("Object.PlanFromDate"), DataCompositionComparisonType.Less);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	// Header of currency balances
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTreeGroup.Name);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".LineKind", 0);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".BankAccountCashAccount",,
		DataCompositionComparisonType.NotFilled);
	
	// Stretching
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTreeStretching.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// The background of Balances is less than or equal to the critical Balance
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTreeBalance.Name);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".BalanceErrorCriticalBalance",
		True);
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.NegativeValueBackColor);
	
	// There were no planned turnovers on any day
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentTree.Name);
	
	FinancialReportingServer.SetFilter(Item.Filter, PaymentTreePath + ".Sum", 0);
		
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Background of the amount of the payment object without the request in the decryption
	
	Item = PaymentsInTheCalendar.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	
	FinancialReportingServer.SetFilter(Item.Filter, "ThereIsErrorApplicationWasNotCreated", True);
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.NegativeValueBackColor);
	Item.Use = True;
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	// The original payment date is less than the one transferred in the decryption
	
	Item = PaymentsInTheCalendar.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	
	FinancialReportingServer.SetFilter(Item.Filter, "ThereIsInitialPaymentDateLessThanRescheduledOne", True);
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.NegativeValueBackColor);
	Item.Use = True;
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	// Differences between the payment currency and the account / cash account currency in the decryption
	
	Item = PaymentsInTheCalendar.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Currency");
	
	FinancialReportingServer.SetFilter(Item.Filter, "ThereIsDifferenceBetweenPaymentCurrencyAndCashAccountAccount", True);
		
	Item.Appearance.SetParameterValue("Font", New Font(Items.PaymentsInTheCalendarCurrency.Font,,,, True));
	Item.Use = True;
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfDaysAndPeriods()

	ConditionalAppearanceForDeletion = New Array;

	For Each AppearanceItem In ConditionalAppearance.Items Do
		If AppearanceItem.Presentation = "DayLongTermPeriod" Then
			ConditionalAppearanceForDeletion.Add(AppearanceItem);
		EndIf;
	EndDo;
	
	For Each AppearanceItem In ConditionalAppearanceForDeletion Do
		ConditionalAppearance.Items.Delete(AppearanceItem);
	EndDo;

	PaymentTreePath = "Object.PaymentTree";
	
	FlagFields = New Array;
	FlagFields.Add(New Structure("Field, AppearanceParameter, AppearanceValue",
		"ErrorCriticalBalance", "BackColor", StyleColors.NegativeValueBackColor));
	
	FlagFields.Add(New Structure("Field, AppearanceParameter, AppearanceValue",
		"ThereIsErrorApplicationWasNotCreated", "BackColor", StyleColors.NegativeValueBackColor));
		
	FlagFields.Add(New Structure("Field, AppearanceParameter, AppearanceValue",
		"ThereIsInitialPaymentDateLessThanRescheduledOne", "BackColor", StyleColors.NegativeValueBackColor));
		
	FontThereIsDifferenceBetweenPaymentCurrenciesAndCashAccountAccount = New Font(Items.PaymentsInTheCalendarCurrency.Font,,,, True);
	FlagFields.Add(New Structure("Field, AppearanceParameter, AppearanceValue",
		"ThereIsDifferenceBetweenPaymentCurrencyAndCashAccountAccount", "Font", FontThereIsDifferenceBetweenPaymentCurrenciesAndCashAccountAccount));

	For Each TreeProps_ In GetAttributes(PaymentTreePath) Do
		If (StrFind(TreeProps_.Name, "Day") > 0 Or StrFind(TreeProps_.Name, "LongTermPeriod") > 0)
			And Items.Find("PaymentTree" + TreeProps_.Name) <> Undefined Then
			
			ItSDay = (StrFind(TreeProps_.Name, "Day") > 0);
			
			If ItSDay Then
				Number = DayNumber(TreeProps_.Name);
				PeriodName = "Day";
				
			Else
				Number = LongTermPeriodNumber(TreeProps_.Name);
				PeriodName = "LongTermPeriod";
			EndIf;
			
			For Each FieldFlag In FlagFields Do
				
				If Number = 0 And FieldFlag.Field = "ErrorCriticalBalance" Then
					Continue;
				EndIf;
				
				Item = ConditionalAppearance.Items.Add();
				
				ItemField = Item.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(Items["PaymentTree" + PeriodName + Number].Name);
				
				FinancialReportingServer.SetFilter(Item.Filter,
					PaymentTreePath + "." + PeriodName + Number + FieldFlag.Field, True);
					
				Item.Appearance.SetParameterValue(FieldFlag.AppearanceParameter, FieldFlag.AppearanceValue);
				Item.Presentation = "DayLongTermPeriod";
			EndDo;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure ChangeFormItemsVisibility()
	
	Items.ChangeTheMode.Picture = ThisForm.Commands["Mode" + ViewMode].Picture;
	
	ApplicationsAreVisible = (ViewMode = "RequestList" Or ViewMode = "ApplicationsCalendar");
	CalendarIsVisible = (ViewMode = "CalendarPayments" Or ViewMode = "ApplicationsCalendar");
	
	Items.GroupLeftColumn.Visible  = ApplicationsAreVisible;
	Items.GroupInTheCalendar.Visible    = Not ApplicationsAreVisible;
	
	Items.GroupRightColumn.Visible         = CalendarIsVisible;
	Items.ShiftUp.Visible               = CalendarIsVisible;
	Items.ShiftDown.Visible                = CalendarIsVisible;
	Items.PaymentTreeCollapseAll.Visible   = CalendarIsVisible;
	Items.PaymentTreeExpandAll.Visible = CalendarIsVisible;
	Items.GroupsControlGroup.Visible = CalendarIsVisible;
	Items.FreezeOverduePayments.Visible = CalendarIsVisible;
	
	Items.AccountFilterSuitable.Visible = ApplicationsAreVisible And CalendarIsVisible;
	
	If CalendarIsVisible Then
		Items.Move(Items.TreeCommandGroup, Items.GroupRightColumn, Items.PaymentPanelGroup);
	Else
		Items.Move(Items.TreeCommandGroup, Items.RequestTeamGroup);
	EndIf;
	
	Items.GroupFilterOfInvoicesAndCashRegisters.Visible = (ViewMode = "ApplicationsCalendar");
	
	If ViewMode = "RequestList" Then
		Items.Move(Items.PlanningGroup_5, Items.GroupCommandBarRequests);
		Items.Move(Items.PaymentList, Items.GroupCommandBarRequests);
	ElsIf ViewMode = "ApplicationsCalendar" Then
		Items.Move(Items.PlanningGroup_5, Items.TreeCommandGroup, Items.FreezeOverduePayments);
		Items.Move(Items.PaymentList, Items.TreeCommandGroup);
	Else
		Items.Move(Items.PlanningGroup_5, Items.TreeCommandGroup, Items.FreezeOverduePayments);
		Items.Move(Items.PaymentList, Items.TreeCommandGroup);
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeVisibilityOfPlanningDays()
	
	NumberOfDays = Object.PlanningDays;
	Indus = 1;
	
	For Indus = 1 To Object.PlanningDays Do
		If Object.HideDaysOff Then
			PaymentDate = CashClientServer.PaymentDate(Object.PlanFromDate, Indus);
			If WeekendDays.FindByValue(PaymentDate) <> Undefined Then
				NumberOfDays = NumberOfDays + 1;
				Items["PaymentTree" + "Day" + Indus].Visible = False;
			Else
				Items["PaymentTree" + "Day" + Indus].Visible = True;
			EndIf;
		Else
			Items["PaymentTree" + "Day" + Indus].Visible = True;
		EndIf;
	EndDo;
	
	DaysPassed = Indus - 1;
	
	For Indus = DaysPassed + 1 To Object.PlanningDays Do
		Items["PaymentTree" + "Day" + Indus].Visible = False;
	EndDo;
	
EndProcedure

#EndRegion

#Region SettingsAndSelections

&AtClient
Procedure OnSettingsChange(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(Object, Result);
	WhenChangingSettingsOnServer();
	ManagingHistoryElements();
	
EndProcedure

&AtServer
Procedure WhenChangingSettingsOnServer()
	
	DataProcessor = FormAttributeToValue("Object");
	FilterPlanningAreas.LoadValues(DataProcessor.PlanningAreas());
	
	UpdateListsOnServer();
	InitializeTheMenuOfGroupingLevels();
	
EndProcedure

&AtClient
Procedure Attachable_SetSelectionInCalendar()
	
	SetCalendarPaymentsSelectionAtServer();
	
EndProcedure

&AtServer
Procedure SetCalendarPaymentsSelectionAtServer()
	
	CommonClientServer.SetDynamicListParameter(PaymentsInTheCalendar, "TaggedEntries",
		TaggedPaymentEntriesInCalendar);
		
	StartDateForDisplayingOverduePayments = DataProcessors.CashForecast.StartDateForDisplayingOverduePayments(
		Object.PlanFromDate, Object.DepthOfDisplayOfOverduePayments);
	CommonClientServer.SetDynamicListParameter(PaymentsInTheCalendar,
		"StartDateForDisplayingOverduePayments", StartDateForDisplayingOverduePayments);
	
	PaymentsInTheCalendar.Filter.Items.Clear();
	
	CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "Frozen",
		FrozenPayments);
		
	CommonClientServer.SetDynamicListFilterItem(
		PaymentsInTheCalendar, "PlanningArea", FilterPlanningAreas,,, FilterPlanningAreas.Count());
		
	If FrozenPayments Then
		
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "PaymentDate",
			Object.EndDate, DataCompositionComparisonType.LessOrEqual,, True);
		
		FilterFields = New Array;
		FilterFields.Add("Organization");
		FilterFields.Add("Currency");
		FilterFields.Add("Bank");
		FilterFields.Add("CashType");
		
		For Each Field In FilterFields Do
			SetPaymentsInCalendarSelectionByField(Field);
		EndDo;
		
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentTreeGrouping) Then
		Return;
	EndIf;
	
	SelectingPaymentsInCalendarList = TMCommonUseClientServer.GetDynamicListSelection(PaymentsInTheCalendar);
	GroupDateOfRelevance = CommonClientServer.CreateFilterItemGroup(
		SelectingPaymentsInCalendarList.Items, "GroupDateOfRelevance", DataCompositionFilterItemsGroupType.OrGroup);
	CommonClientServer.AddCompositionItem(
		GroupDateOfRelevance, "ScheduleRelevanceDate", DataCompositionComparisonType.Equal, Date(1,1,1),, True);
	CommonClientServer.AddCompositionItem(
		GroupDateOfRelevance, "ScheduleRelevanceDate", DataCompositionComparisonType.GreaterOrEqual,
		Object.PlanFromDate,, True);
	
	If ValueIsFilled(CurrentTreeColumn) Then
	
		If CurrentTreeColumn = "PaymentTreeBalance"
			Or CurrentTreeColumn = "PaymentTreeStretching" Then // We don't show anything
			
			CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "PaymentDate",
				Date("39990101"),,, True);
		Else
			CurrentCalendarDate = AllocatedDay(CurrentTreeColumn, Object.PlanFromDate);
			
			If ValueIsFilled(CurrentCalendarDate) Then
				
				CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar,
					"PaymentDate", CurrentCalendarDate,
					?(CurrentCalendarDate < Object.PlanFromDate, DataCompositionComparisonType.LessOrEqual,
						DataCompositionComparisonType.Equal),, True);
			Else
				CurrentLongTermPeriodStartDate = AllocatedLongTermPeriod(CurrentTreeColumn,
					Object.EndDateOfPlanningByDay, Object.LongTermPlanningTimeFence);
					
				If ValueIsFilled(CurrentLongTermPeriodStartDate) Then

					CurrentLongTermPeriodEndDate = WorkingWithClientServerPeriods.PeriodEndDate_(
						CurrentLongTermPeriodStartDate, Object.LongTermPlanningTimeFence);
					
					AdditionalParameters = New Structure("ReplaceCurrent", False);
						
					DataCompositionClientServer.AddFilter(PaymentsInTheCalendar.Filter, "PaymentDate",
						CurrentLongTermPeriodStartDate, DataCompositionComparisonType.GreaterOrEqual,,
						AdditionalParameters);
						
					DataCompositionClientServer.AddFilter(PaymentsInTheCalendar.Filter, "PaymentDate",
						CurrentLongTermPeriodEndDate, DataCompositionComparisonType.LessOrEqual,,
						AdditionalParameters);
				Else
					CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar,
						"PaymentDate", Object.EndDate, DataCompositionComparisonType.LessOrEqual,, True);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.FilterCurrency) Then
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "PaymentCurrency",
			Object.FilterCurrency,,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "PaymentCurrency",
			CurrentCurrency,,, ValueIsFilled(CurrentCurrency));
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "ReceiptIssue",
		CurrentMovementType,,, ValueIsFilled(CurrentMovementType));
	
	CheckoutInvoiceComparisonType = DataCompositionComparisonType.Equal;
	UseSelectionByInvoiceCheckout = ValueIsFilled(CurrentBankAccountCashAccount);
	
	If TypeOf(CurrentTreeGrouping) = Type("String") Then
		If CurRowOfTreeIsNotDistributed Then
			CheckoutInvoiceComparisonType = DataCompositionComparisonType.NotFilled;
			UseSelectionByInvoiceCheckout = True;
		ElsIf CurRowOfTreeIsDistributed Then
			CheckoutInvoiceComparisonType = DataCompositionComparisonType.Filled;
			UseSelectionByInvoiceCheckout = True;
		ElsIf CurrentTreeGrouping = "InTotal" Then
			UseSelectionByInvoiceCheckout = False;
		EndIf;
	EndIf;
	
	If UseSelectionByInvoiceCheckout Then
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar,
			"BankAccountCashAccount", CurrentBankAccountCashAccount, CheckoutInvoiceComparisonType,, True);
	Else
		SetPaymentsInCalendarSelectionByField("BankAccountCashAccount");
	EndIf;
	
	If ValueIsFilled(CurrentCompany) Then
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "Organization",
			CurrentCompany,,, ValueIsFilled(CurrentCompany));
	Else
		SetPaymentsInCalendarSelectionByField("Organization");
	EndIf;
		
	If ValueIsFilled(CurrentTypeOfFunds) Then
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "CashType",
			CurrentTypeOfFunds,,, True);
	Else
		SetPaymentsInCalendarSelectionByField("CashType");
	EndIf;
	
	If ValueIsFilled(CurBank) Then
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, "Bank",
			CurBank,,, True);
	Else
		SetPaymentsInCalendarSelectionByField("Bank");
	EndIf;
		
EndProcedure

&AtServer
Procedure SetDynamicListSelections()
	
	If CurrentListName = "PaymentsInTheCalendar" Then
		Return;
	EndIf;
	
	DynamicList = ThisForm[CurrentListName];
	
	Companies = New Array;
	For Each FilterElement In Object.FilterCompanies Do
		If FilterElement.Check Then
			Companies.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		DynamicList,
		"Organization",
		Companies,,,
		Companies.Count());
		
	CommonClientServer.SetDynamicListFilterItem(
		DynamicList,
		"Currency",
		Object.FilterCurrency,,,
		ValueIsFilled(Object.FilterCurrency));
		
	CommonClientServer.SetDynamicListFilterItem(
		DynamicList,
		"PaymentDate",
		CashClientServer.PaymentDate(Object.PlanFromDate, Object.PlanningDays),
		DataCompositionComparisonType.LessOrEqual);
		
	CommonClientServer.SetDynamicListFilterItem(
		DynamicList,
		"PlanningArea",
		FilterPlanningAreas,,,
		FilterPlanningAreas.Count());
		
	CommonClientServer.SetDynamicListParameter(DynamicList, "TaggedEntries",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
		
EndProcedure

&AtClient
Procedure OpenBankAccountSettingsForm()
	
	FillInListOfCheckoutInvoicesOnServer();
	
	ClosingNotification1 = New CallbackDescription("ChoosingBankAccounts", ThisObject);
	
	Marked = New ValueList;
	For Each ElementSelectionBankAccountsCashRegisters In Object.FilterBankAccountsCashAccounts Do
		If ElementSelectionBankAccountsCashRegisters.Check Then
			Marked.Add(ElementSelectionBankAccountsCashRegisters.Value, , True);
		EndIf;
	EndDo;
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CompaniesBankAccounts"));
	TypesArray.Add(Type("CatalogRef.CashAccounts"));
	TypesArray.Add(Type("String"));
	AllowedTypes = New TypeDescription(TypesArray);
	
	FormParameters = New Structure;
	FormParameters.Insert("RestrictSelectionBySpecifiedValues", True);
	FormParameters.Insert("Presentation", NStr("vi = 'Lựa chọn tài khoản ngân hàng / quỹ tiền mặt';
												|ru = 'Отбор банковских счетов / касс';
												|en = 'Filter bank accounts / cash accounts'; fa = 'Filter bank accounts / cash accounts';
												|it = 'Selezione conti correnti/casse';
												|pl = 'Filtr rachunków bankowych / kas';
												|tr = 'Banka hesapları / kasa filtresi'"));
	FormParameters.Insert("ValuesForSelection", Object.FilterBankAccountsCashAccounts);
	FormParameters.Insert("TypeDescription", AllowedTypes);
	FormParameters.Insert("Marked", Marked);
	
	OpenForm("CommonForm.InputValuesInListWithCheckBoxes", FormParameters, ThisObject,,,,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChoosingBankAccounts(Result, AdditionalParameters) Export
	
	If Result <> Undefined And TypeOf(Result) = Type("ValueList") Then
		Object.FilterBankAccountsCashAccounts = Result;
		FilterBankAccountCashAccountPresentation = FilterPresentation(Object.FilterBankAccountsCashAccounts);
		If Not ValueIsFilled(FilterBankAccountCashAccountPresentation) Then
			Object.CalendarAccountFilter = 0;
		Else
			Object.CalendarAccountFilter = 1;
		EndIf;
		InstallComposerSelectionBySelectionBankAccountsCashAccounts(Object.LinkerSelection, Object.FilterBankAccountsCashAccounts);
		UpdatedList_4();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatedList_4()
	
	CheckPlanningDateAndUpdateLists();
	ManagingHistoryElements();
	
EndProcedure

&AtServer
Procedure CheckPlanningDateAndUpdateLists()
	
	UpdateListsOnServer();
	
EndProcedure

&AtServer
Procedure UpdateListsOnServer()
	
	SetDynamicListSelections();
	
	If ViewMode <> "RequestList" Then
		
		KeyOperation = "CashForecasting.UpdatingPaymentCalendarData";
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
		
		AddDaysColumns();
		AddLongTermPlanningColumns();
		
		DataProcessor = FormAttributeToValue("Object");
		DataProcessor.CalculateCalendarData(CalendarCalculationParameters());
		ValueToFormAttribute(DataProcessor, "Object");
		
		Items.PaymentPanelGroup.CurrentPage = Items.PagePaymentTree;
		
		ChangeVisibilityOfPlanningDays();
		
		MarkInvoiceFilter();
		
		If CurrentTreeColumn <> Undefined Then
			Control = Items.PaymentTree.ChildItems.Find(CurrentTreeColumn);
			If Control <> Undefined Then
				Items.PaymentTree.CurrentItem = Control;
			EndIf;
		EndIf;
		
		StringSearchDetails = New Structure;
		StringSearchDetails.Insert("Group", CurrentTreeGrouping);
		StringSearchDetails.Insert("LineKind", CurrentLineKind);
		StringSearchDetails.Insert("BankAccountCashAccount", CurrentBankAccountCashAccount);
		StringSearchDetails.Insert("Currency", CurrentCurrency);
		
		FoundRow = SubordinateItem(Object.PaymentTree, StringSearchDetails);
		If FoundRow <> Undefined Then
			Items.PaymentTree.CurrentRow = FoundRow.GetID();
		EndIf;
		
		If ViewMode = "CalendarPayments" Then
			SetCalendarPaymentsSelectionAtServer();
		EndIf;
		
		ChangeHistory.Clear();
		CurrentHistoryIndex = 0;
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"AdvancedFilter",
		"Title",
		GetTitleOfHyperlinkAdvancedSelection(Object.LinkerSelection));
	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfDimensions()
	
	UserSettings = ThisForm[CurrentListName].SettingsComposer.UserSettings; // DataCompositionUserSettings 
	SettingUpAGrouping = UserSettings.Items[3];
	
	GroupName = "";
	If SettingUpAGrouping.Structure.Count() = 1 Then
		GroupFields = SettingUpAGrouping.Structure[0].GroupFields; // DataCompositionGroupFields
		GroupName = String(GroupFields.Items[0].Field);
	EndIf;
	
	MarkListGrouping(GroupName);
	
EndProcedure

&AtServer
Function ParametersOfExtendedSelectionForm()
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter_Settings", Object.LinkerSelection.GetSettings());
	OpeningParameters.Insert("HideServiceSelections", True);
	
	Return OpeningParameters;
	
EndFunction

&AtClient
Procedure SetAdvancedSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	InstallSelectionsOnServer(Result.Filter_Settings);

EndProcedure

&AtServer
Procedure InstallSelectionsOnServer(Val Filter_Settings)

	Object.LinkerSelection.LoadSettings(Filter_Settings);
	SetCompanySelectionByComposerSelection(Object.LinkerSelection, Object.FilterCompanies);
	SetSelectionCurrencyByComposerSelection(Object.LinkerSelection, Object.FilterCurrency);
	SetSelectionOfBankAccountsCashAccountsByComposerSelection(Object.LinkerSelection, Object.FilterBankAccountsCashAccounts);
	
	FilterCompaniesPresentation = FilterPresentation(Object.FilterCompanies);
	FilterBankAccountCashAccountPresentation = FilterPresentation(Object.FilterBankAccountsCashAccounts);
	
	UpdateListsOnServer();

EndProcedure

&AtServerNoContext
Function GetTitleOfHyperlinkAdvancedSelection(Val Filter_Settings)
	
	NumberOfSelections = 0;
	Title = NStr("vi = 'Bộ lọc nâng cao';
				|ru = 'Расширенный отбор';
				|en = 'Advanced filter'; fa = 'فیلتر پیشرفته';
				|it = 'Расширенный отбор';
				|pl = 'Rozszerzony filtr';
				|tr = 'Gelişmiş filtre'");
	FilterText1 = "";
	
	FilterFields = New ValueList;
	FilterFields.Add("Currency", NStr("vi = 'Tiền tệ';
										|ru = 'Валюта';
										|en = 'Currency'; fa = 'ارز';
										|it = 'Valuta';
										|pl = 'Waluta';
										|tr = 'Para birimi'"));
	FilterFields.Add("Organization", NStr("vi = 'Doanh nghiệp';
											|ru = 'Организация';
											|en = 'Company'; fa = 'Company';
											|it = 'Azienda';
											|pl = 'Firma';
											|tr = 'İş yeri'"));
	FilterFields.Add("CashType", NStr("vi = 'Kiểu vốn bằng tiền';
										|ru = 'Тип денежных средств';
										|en = 'Cash type'; fa = 'نوع وجه نقد';
										|it = 'Tipo di fondi monetari';
										|pl = 'Typ środków pieniężnych';
										|tr = 'Nakit tipi'"));
	FilterFields.Add("CashAccountBank", NStr("vi = 'Ngân hàng';
											|ru = 'Банк';
											|en = 'Bank'; fa = 'بانک';
											|it = 'Bank';
											|pl = 'Bank';
											|tr = 'Banka'"));
	FilterFields.Add("BankAccountCashAccount", NStr("vi = 'Tài khoản ngân hàng / Tiền mặt';
													|ru = 'Банковский счет / Касса';
													|en = 'Bank account / Cash account'; fa = 'حساب بانکی / صندوق';
													|it = 'Conto bancario / Cassa';
													|pl = 'Rachunek bankowy / Kasa';
													|tr = 'Banka hesabı / Kasa'"));
	
	For Each Field In FilterFields Do
		FilterElement = FindSelectionElementWithoutSearchingInGroups(Filter_Settings.Settings.Filter, Field.Value);

		If FilterElement <> Undefined And FilterElement.Use Then
			FilterText1 = FilterText1 + ?(IsBlankString(FilterText1), "", ", ") + Field.Presentation;
			NumberOfSelections = NumberOfSelections + 1;
		EndIf;
	EndDo;
	
	If NumberOfSelections = 0 Then
		For Each FilterElement In Filter_Settings.Settings.Filter.Items Do
			If FilterElement.Use Then
				NumberOfSelections = NumberOfSelections + 1;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(FilterText1) Then
		Title = ?(NumberOfSelections > 2,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặt lọc: %1';
																			|ru = 'Установлено отборов: %1';
																			|en = 'Active filters: %1'; fa = 'Active filters: %1';
																			|it = 'Selezioni impostate: %1';
																			|pl = 'Ustawiono filtrów: %1';
																			|tr = 'Filtreler ayarlandı: %1'"), NumberOfSelections),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặt lọc theo: %1';
																			|ru = 'Установлен отбор по: %1';
																			|en = 'Filter by %1 is set'; fa = 'Filter by %1 is set';
																			|it = 'Filter by %1 is set';
																			|pl = 'Filter by %1 is set';
																			|tr = 'Filtre ayarlama kriteri: %1'"), FilterText1));
	ElsIf NumberOfSelections > 0 Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặt lọc: %1';
																				|ru = 'Установлено отборов: %1';
																				|en = 'Active filters: %1'; fa = 'Active filters: %1';
																				|it = 'Selezioni impostate: %1';
																				|pl = 'Ustawiono filtrów: %1';
																				|tr = 'Filtreler ayarlandı: %1'"),
			NumberOfSelections);
	EndIf;
	
	Return Title;
	
EndFunction

// Sets the selection for the "Organization" field in the transmitted settings Composer.
// 
// Parameters:
//  LinkerSelection - DataCompositionSettingsComposer
//  FilterCompanies - ValueList of CatalogRef.Companies
//
&AtServerNoContext
Procedure SetCompanySelectionByComposerSelection(Val LinkerSelection, FilterCompanies)
	
	FilterCompanies.FillChecks(False);
	
	FilterElement = FindSelectionItemWithoutSearchingInGroupsEqualToInList(LinkerSelection.Settings.Filter, "Organization");
	
	If FilterElement <> Undefined And FilterElement.Use
		And ValueIsFilled(FilterElement.RightValue) Then
	
		If TypeOf(FilterElement.RightValue) = Type("CatalogRef.Companies") Then
			
			ListItem = FilterCompanies.FindByValue(FilterElement.RightValue);
			
			If ListItem = Undefined Then
				FilterCompanies.Add(FilterElement.RightValue, , True);
			Else
				ListItem.Check = True;
			EndIf;
			
		ElsIf TypeOf(FilterElement.RightValue) = Type("ValueList") Then

			For Each ArrayElement In FilterElement.RightValue Do // ValueListItem
				
				ListItem = FilterCompanies.FindByValue(FilterElement.RightValue);
			
				If ListItem = Undefined Then
					FilterCompanies.Add(ArrayElement.Value, , True);
				Else
					ListItem.Check = True;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Sets the selection for the "Bank Account" field in the transmitted settings Composer.
// 
// Parameters:
//  LinkerSelection - DataCompositionSettingsComposer
//  FilterBankAccountsCashAccounts - ValueList of CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts
//
&AtServerNoContext
Procedure SetSelectionOfBankAccountsCashAccountsByComposerSelection(Val LinkerSelection, FilterBankAccountsCashAccounts)

	FilterBankAccountsCashAccounts.FillChecks(False);

	FilterElement = FindSelectionItemWithoutSearchingInGroupsEqualToInList(LinkerSelection.Settings.Filter, "BankAccountCashAccount");
	
	If FilterElement <> Undefined And FilterElement.Use
		And ValueIsFilled(FilterElement.RightValue) Then
	
		If TypeOf(FilterElement.RightValue) = Type("ValueList") Then

			For Each ArrayElement In FilterElement.RightValue Do // ValueListItem
				
				ListItem = FilterBankAccountsCashAccounts.FindByValue(FilterElement.RightValue);
			
				If ListItem = Undefined Then
					FilterBankAccountsCashAccounts.Add(ArrayElement.Value, , True);
				Else
					ListItem.Check = True;
				EndIf;
			EndDo;
		Else
			ListItem = FilterBankAccountsCashAccounts.FindByValue(FilterElement.RightValue);
			
			If ListItem = Undefined Then
				FilterBankAccountsCashAccounts.Add(FilterElement.RightValue, , True);
			Else
				ListItem.Check = True;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure SetSelectionCurrencyByComposerSelection(Val LinkerSelection, FilterCurrency)
	
	FilterCurrency = Catalogs.Currencies.EmptyRef();
	FilterElement = FindSelectionItemWithoutSearchingInGroupsEqualToInList(LinkerSelection.Settings.Filter, "Currency");
	
	If FilterElement <> Undefined And FilterElement.Use
		And ValueIsFilled(FilterElement.RightValue) Then
	
		If TypeOf(FilterElement.RightValue) = Type("CatalogRef.Currencies") Then
			FilterCurrency = FilterElement.RightValue;
			
		ElsIf TypeOf(FilterElement.RightValue) = Type("ValueList") Then
			
			If FilterElement.RightValue.Count() = 1 Then
				FilterCurrency = FilterElement.RightValue[0].Value;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure InstallComposerSelectionByCompanySelection(LinkerSelection, Val FilterCompanies)

	Companies = New ValueList;
	For Each FilterElement In FilterCompanies Do
		If FilterElement.Check Then
			Companies.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	ListIsNotEmpty = (Companies.Count() > 0);
	SetSelectionWithoutSearchingInGroups(LinkerSelection.Settings.Filter, "Organization", Companies,, ListIsNotEmpty);

EndProcedure

&AtServerNoContext
Procedure InstallComposerSelectionBySelectionCurrency(LinkerSelection, Val FilterCurrency)

	SetSelectionWithoutSearchingInGroups(LinkerSelection.Settings.Filter, "Currency", FilterCurrency,,
		ValueIsFilled(FilterCurrency));

EndProcedure

&AtServerNoContext
Procedure InstallComposerSelectionBySelectionBankAccountsCashAccounts(LinkerSelection, Val FilterBankAccountsCashAccounts)

	BankAccountsCashAccounts = New ValueList;
	For Each FilterElement In FilterBankAccountsCashAccounts Do
		If FilterElement.Check Then
			BankAccountsCashAccounts.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	ListIsNotEmpty = (BankAccountsCashAccounts.Count() > 0);
	SetSelectionWithoutSearchingInGroups(LinkerSelection.Settings.Filter, "BankAccountCashAccount", BankAccountsCashAccounts,,
		ListIsNotEmpty);

EndProcedure

&AtServer
Procedure SetPaymentsInCalendarSelectionByField(FieldName)
	
	FilterFields = FindSelectionItemWithoutSearchingInGroupsEqualToInList(Object.LinkerSelection.Settings.Filter, FieldName);
	
	If FilterFields <> Undefined Then
		CommonClientServer.SetDynamicListFilterItem(PaymentsInTheCalendar, FieldName,
			FilterFields.RightValue, FilterFields.ComparisonType,, FilterFields.Use);
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure MarkInvoiceFilter()
	
	Items.AccountFilterAll.Check = (Object.CalendarAccountFilter = 0);
	Items.AccountFilterSelected.Check = (Object.CalendarAccountFilter = 1);
	Items.AccountFilterSuitable.Check = (Object.CalendarAccountFilter = 2);
	
	If Object.CalendarAccountFilter = 0 Then
		FilterHeader = NStr("vi = 'Tài khoản / Tiền mặt: Tất cả';
							|ru = 'Счета / Кассы: Все';
							|en = 'Bank / Cash accounts: All'; fa = 'Bank / Cash accounts: All';
							|it = 'Сonti / Casse: Tutti';
							|pl = 'Konta / Kasy: Wszystkie';
							|tr = 'Hesaplar / Kasalar: Tümü'");
	ElsIf Object.CalendarAccountFilter = 1 Then
		FilterHeader = NStr("vi = 'Tài khoản / Tiền mặt: Đã chọn';
							|ru = 'Счета / Кассы: Выбранные';
							|en = 'Bank / Cash accounts: Selected'; fa = 'Bank / Cash accounts: Selected';
							|it = 'Сonti / Casse: Selezionate';
							|pl = 'Konta / Kasy: Wybrane';
							|tr = 'Hesaplar / Kasalar: Seçilenler'");
	ElsIf Object.CalendarAccountFilter = 2 Then
		FilterHeader = NStr("vi = 'Tài khoản / Tiền mặt: Thích hợp';
							|ru = 'Счета / Кассы: Подходящие';
							|en = 'Bank / Cash accounts: Suitable'; fa = 'Bank / Cash accounts: Suitable';
							|it = 'Сonti / Casse: Idonei';
							|pl = 'Konta / Kasy: Pasujące';
							|tr = 'Hesaplar / Kasalar: Uygun olanlar'");
	EndIf;
	
	Items.GroupFilterOfInvoicesAndCashRegisters.Title = FilterHeader;
	
EndProcedure

&AtServer
Procedure MarkListGrouping(GroupName)
	
	If CurrentListName = "PaymentRequests" Then
		Items.PaymentRequestsGroupingCashFlowItemPriority.Check        = (GroupName = "CashFlowItemPriority");
		Items.RequestsForPaymentGroupingArticleDDS.Check                 = (GroupName = "CFItem");
		Items.RequestsForPaymentGroupingPriorityOfTheRequest.Check           = (GroupName = "RequestPriority");
		Items.RequestsForPaymentGroupingBusinessOperation.Check     = (GroupName = "Operation");
		Items.RequestsForPaymentGroupingDivision.Check             = (GroupName = "Department");
		Items.RequestsForPaymentGroupingPayerRecipient.Check      = (GroupName = "PayerBeneficiary");
		Items.RequestsForPaymentWithoutGrouping.Check                       = (GroupName = "");
	Else
		Items.PaymentsInTheCalendarGroupingCashFlowItemPriority.Check    = (GroupName = "CashFlowItemPriority");
		Items.PaymentsInTheCalendarGroupingArticleDDS.Check             = (GroupName = "CFItem");
		Items.PaymentsInTheCalendarGroupingPriorityOfTheRequest.Check       = (GroupName = "RequestPriority");
		Items.PaymentsInTheCalendarGroupingBusinessTransaction.Check = (GroupName = "Operation");
		Items.PaymentsInTheCalendarGroupingDivision.Check         = (GroupName = "Department");
		Items.PaymentsInTheCalendarGroupingPayerRecipient.Check  = (GroupName = "PayerBeneficiary");
		Items.PaymentsInTheCalendarWithoutGrouping.Check                   = (GroupName = "");
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeOrganizationSelection()
	
	AvailableCompanies = Catalogs.Companies.AvailableCompanies(True, False);
	Items.FilterCompanies.ChoiceList.LoadValues(AvailableCompanies);
	Object.FilterCompanies.LoadValues(AvailableCompanies);
	FilterCompanies.LoadValues(AvailableCompanies);
	
EndProcedure

&AtClient
Procedure OpenPaymentObject()
	
	CurrentRow = Items[CurrentListName].CurrentRow;
	
	If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
		
		ShowValue(, CurrentRow.Key);
		
	Else
		CurrentData = Items[CurrentListName].CurrentData;
		
		If CurrentData <> Undefined Then
			ShowValue(, CurrentData.PaymentObject);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function CalendarCalculationParameters()
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("FormID", UUID);
	
	If Object.CalendarAccountFilter = 2 Then
		CalculationParameters.Insert("Request", CurrentRequest);
	EndIf;
	
	Return CalculationParameters;
	
EndFunction

&AtServer
Procedure AddDaysColumns()
	
	FillInDaysOff();
	
	NumberDetails = TMCommonUse.MoneyFieldTypeDescription();
	AttributesPath = "Object.PaymentTree";
	
	TotalColumnsOfLongTermPeriods = 0;
	For Each TreeProps_ In GetAttributes(AttributesPath) Do
		If StrFind(TreeProps_.Name, "LongTermPeriod") > 0 Then
			TotalColumnsOfLongTermPeriods = TotalColumnsOfLongTermPeriods + 1;
		EndIf;
	EndDo;
	
	SubordinateElements = GetAttributes(AttributesPath).Count();
	TotalColumnsOfDays = (SubordinateElements - TreeItemsWithoutAddedDays - TotalColumnsOfLongTermPeriods) / 7;
	
	DetailsToAdd_ = New Array;
	ElementsToAdd = New Array; // Array of FormField
	DetailsToDelete = New Array;
	
	Fields = New Map;
	Fields.Insert("InCurrency", NumberDetails);
	Fields.Insert("InOneCurrency", NumberDetails);
	Fields.Insert("ErrorCriticalBalance", New TypeDescription("Boolean"));
	Fields.Insert("ThereIsErrorApplicationWasNotCreated", New TypeDescription("Boolean"));
	Fields.Insert("ThereIsInitialPaymentDateLessThanRescheduledOne", New TypeDescription("Boolean"));
	Fields.Insert("ThereIsDifferenceBetweenPaymentCurrencyAndCashAccountAccount", New TypeDescription("Boolean"));
	
	While TotalColumnsOfDays > Object.PlanningDays + 1 Do
		DayNumber = TotalColumnsOfDays - 1;
		PathOfAttributeBeingDeleted = AttributesPath + ".Day" + String(DayNumber);
		DetailsToDelete.Add(PathOfAttributeBeingDeleted);
		
		For Each Field In Fields Do
			DetailsToDelete.Add(PathOfAttributeBeingDeleted + Field.Key);
		EndDo;
		TotalColumnsOfDays = DayNumber;
	EndDo;
	
	For Indus = TotalColumnsOfDays To Object.PlanningDays Do
		
		AttributeName = "Day" + Indus;
		
		TreeProps_ = New FormAttribute(AttributeName, NumberDetails, AttributesPath);
		DetailsToAdd_.Add(TreeProps_);
		ElementsToAdd.Add(TreeProps_);
		
		For Each Field In Fields Do
			TreeProps_ = New FormAttribute(AttributeName + Field.Key, Field.Value, AttributesPath);
			DetailsToAdd_.Add(TreeProps_);
		EndDo;
	EndDo;
	
	ChangeAttributes(DetailsToAdd_, DetailsToDelete);
	
	ElementPaymentTreeLongTermPeriod1 = Items.Find("PaymentTreeLongTermPeriod1");
	LastElementInPaymentTree = ?(ElementPaymentTreeLongTermPeriod1 <> Undefined,
		ElementPaymentTreeLongTermPeriod1, Items.PaymentTreeStretching);
	
	For Each ItemToAdd_ In ElementsToAdd Do
		NewItem = Items.Insert("PaymentTree" + ItemToAdd_.Name, Type("FormField"), Items.PaymentTree, 
			LastElementInPaymentTree);
		NewItem.Type = FormFieldType.LabelField;
		NewItem.DataPath = AttributesPath + "." + ItemToAdd_.Name;
		NewItem.Width = 12;
		NewItem.HorizontalStretch = False;
		NewItem.HorizontalAlign = ItemHorizontalLocation.Right;
	EndDo;
	
	ElementDay0 = Items.Find("PaymentTree" + "Day0");
	If ElementDay0 <> Undefined Then
		ElementDay0.Title = NStr("vi = 'Đã quá hạn';
								|ru = 'Просрочено';
								|en = 'Overdue'; fa = 'سررسیدگذشته';
								|it = 'Scaduto';
								|pl = 'Overdue';
								|tr = 'Vadesi geçmiş'");
		ElementDay0.TextColor = StyleColors.OverdueDataColor;
		ElementDay0.TitleTextColor = StyleColors.OverdueDataColor;
	EndIf;
	Days.Clear();
	
	For Indus = 1 To Object.PlanningDays Do
		TagName = "PaymentTree" + "Day" + Indus;
		DateOfTitle = CashClientServer.PaymentDate(Object.PlanFromDate, Indus);
		newRow_ = Days.Add();
		newRow_.FieldName = TagName;
		newRow_.Date = DateOfTitle;
		
		Items[TagName].Title =
			Format(DateOfTitle, NStr("vi = 'ДФ=''ддд''';
									|ru = 'ДФ=''ддд''';
									|en = 'DF=''ddd'''; fa = 'DF=''ddd''';
									|it = 'ДФ=''ддд''';
									|pl = 'DF=''ddd''';
									|tr = 'DF=''ddd'''")) + " " + Format(DateOfTitle, "DLF=D");
		
		If WeekendDays.FindByValue(DateOfTitle) <> Undefined Then
			Items[TagName].TitleTextColor = StyleColors.GrayTextColor1;
		Else
			Items[TagName].TitleTextColor = New Color();
		EndIf;
	EndDo;
	
	If DetailsToAdd_.Count() > 0 Or DetailsToDelete.Count() > 0 Then
		SetConditionalAppearanceOfDaysAndPeriods();
	EndIf;
	
EndProcedure

&AtServer
Procedure AddLongTermPlanningColumns()
	
	NumberDetails = TMCommonUse.MoneyFieldTypeDescription();
	AttributesPath = "Object.PaymentTree";
	
	TreeDetails = GetAttributes(AttributesPath);
	SubordinateElements = TreeDetails.Count();
	TotalColumnsOfDays = 0;
	
	For Each TreeProps_ In TreeDetails Do
		If StrFind(TreeProps_.Name, "Day") > 0 Then
			TotalColumnsOfDays = TotalColumnsOfDays + 1;
		EndIf; 
	EndDo;
	
	TotalColumnsOfLongTermPeriods = (SubordinateElements - TreeItemsWithoutAddedDays - TotalColumnsOfDays) / 7;
	
	DetailsToAdd_ = New Array;
	ElementsToAdd = New Array; // Array of FormField
	DetailsToDelete = New Array;
	
	Fields = New Map;
	Fields.Insert("InCurrency", NumberDetails);
	Fields.Insert("InOneCurrency", NumberDetails);
	Fields.Insert("ErrorCriticalBalance", New TypeDescription("Boolean"));
	Fields.Insert("ThereIsErrorApplicationWasNotCreated", New TypeDescription("Boolean"));
	Fields.Insert("ThereIsInitialPaymentDateLessThanRescheduledOne", New TypeDescription("Boolean"));
	Fields.Insert("ThereIsDifferenceBetweenPaymentCurrencyAndCashAccountAccount", New TypeDescription("Boolean"));
	
	While TotalColumnsOfLongTermPeriods > Object.LongTermPlanningPeriods Do
		PeriodNumber = TotalColumnsOfLongTermPeriods;
		PathOfAttributeBeingDeleted = AttributesPath + ".LongTermPeriod" + String(PeriodNumber);
		DetailsToDelete.Add(PathOfAttributeBeingDeleted);
		
		For Each Field In Fields Do
			DetailsToDelete.Add(PathOfAttributeBeingDeleted + Field.Key);
		EndDo;
		TotalColumnsOfLongTermPeriods = PeriodNumber - 1;
	EndDo;
	
	For Indus = TotalColumnsOfLongTermPeriods + 1 To Object.LongTermPlanningPeriods Do
		
		AttributeName = "LongTermPeriod" + Indus;
		
		TreeProps_ = New FormAttribute(AttributeName, NumberDetails, AttributesPath);
		DetailsToAdd_.Add(TreeProps_);
		ElementsToAdd.Add(TreeProps_);
		
		For Each Field In Fields Do
			TreeProps_ = New FormAttribute(AttributeName + Field.Key, Field.Value, AttributesPath);
			DetailsToAdd_.Add(TreeProps_);
		EndDo;
	EndDo;
	
	ChangeAttributes(DetailsToAdd_, DetailsToDelete);
	
	For Each ItemToAdd_ In ElementsToAdd Do
		NewItem = Items.Insert("PaymentTree" + ItemToAdd_.Name, Type("FormField"), 
			Items.PaymentTree, Items.PaymentTreeStretching);
		NewItem.Type = FormFieldType.LabelField;
		NewItem.DataPath = AttributesPath + "." + ItemToAdd_.Name;
		NewItem.Width = 12;
		NewItem.HorizontalStretch = False;
		NewItem.HorizontalAlign = ItemHorizontalLocation.Right;
	EndDo;
	
	BeginningDateOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(Object.EndDateOfPlanningByDay,
		Object.LongTermPlanningTimeFence) + 86400;
	BeginningDateOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(BeginningDateOfPeriod,
		Object.LongTermPlanningTimeFence);
	EndingDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(BeginningDateOfPeriod, 
		Object.LongTermPlanningTimeFence);
	LongTermPeriods.Clear();
	
	For Indus = 1 To Object.LongTermPlanningPeriods Do
		TagName = "PaymentTree" + "LongTermPeriod" + Indus;
		newRow_ = LongTermPeriods.Add();
		newRow_.Number = Indus;
		newRow_.FieldName = TagName;
		newRow_.StartDate = BeginningDateOfPeriod;
		newRow_.EndDate = EndingDateOfPeriod;
		
		PeriodHeader = PlanningClientServer.GeneratePeriodHeader(Object.LongTermPlanningTimeFence, 
			BeginningDateOfPeriod, EndingDateOfPeriod);
		Items[TagName].Title = PeriodHeader;
		BeginningDateOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(EndingDateOfPeriod+1,
			Object.LongTermPlanningTimeFence);
		EndingDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(EndingDateOfPeriod+1, 
			Object.LongTermPlanningTimeFence);
	EndDo;
	
	If DetailsToAdd_.Count() > 0 Or DetailsToDelete.Count() > 0 Then
		SetConditionalAppearanceOfDaysAndPeriods();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDaysOff()
	
	WeekendDays.Clear();
	
	If ValueIsFilled(MainEnterpriseCalendar) Then
		
		PlanningDays_ = New Array;
		
		For Indus = 1 To Object.PlanningDays Do
			PlanningDays_.Add(CashClientServer.PaymentDate(Object.PlanFromDate, Indus));
		EndDo;
		
		SetPrivilegedMode(True);
		BusinessCalendar = Common.ObjectAttributeValue(MainEnterpriseCalendar, "BusinessCalendar");
		ReceivingParameters = CalendarSchedules.NearestWorkDatesReceivingParameters();
		ReceivingParameters.GetPrevious = False;
		ReceivingParameters.RaiseException1 = False;
		CalendarDays_1 = CalendarSchedules.NearestWorkDates(BusinessCalendar, PlanningDays_, ReceivingParameters);
		SetPrivilegedMode(False);
		
		If CalendarDays_1 <> Undefined Then
			For Each CalendarDay In CalendarDays_1 Do
				If CalendarDay.Key <> CalendarDay.Value Then
					WeekendDays.Add(CalendarDay.Key);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function AllocatedDay(TreeColumnName, PlanFromDate)
	
	ItemNumberOfDay = Find(TreeColumnName, "Day");
	If ItemNumberOfDay Then
		DayNumber = Right(TreeColumnName, StrLen(TreeColumnName) - ItemNumberOfDay - StrLen("Day") + 1);
		Return CashClientServer.PaymentDate(PlanFromDate, Number(DayNumber))
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function AllocatedLongTermPeriod(TreeColumnName, EndDateOfPlanningByDay,
	LongTermPlanningTimeFence)
	
	ItemNumberOfPeriod = StrFind(TreeColumnName, "LongTermPeriod");
	If ItemNumberOfPeriod > 0 Then
		PeriodNumber = Right(TreeColumnName, StrLen(TreeColumnName) - ItemNumberOfPeriod 
			- StrLen("LongTermPeriod") + 1);
		Date = WorkingWithClientServerPeriods.AddInterval(EndDateOfPlanningByDay, 
			LongTermPlanningTimeFence, PeriodNumber);
		
		Return WorkingWithClientServerPeriods.BeginningDateOfPeriod(Date, LongTermPlanningTimeFence);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Procedure SelectionOfApplicationsWhenChangingOnServer()
	
	Items.PaymentRequestsSum.Visible = Not PickRequests;
	Items.PaymentRequestsBankAccountCashAccount.Visible = Not PickRequests;
	
	CommonClientServer.SetDynamicListFilterItem(
		PaymentRequests,
		"BankAccountCashAccount",,
		DataCompositionComparisonType.NotFilled,,
		PickRequests);
	
	CommonClientServer.SetDynamicListFilterItem(PaymentRequests, "Frozen", FrozenPayments);
	
EndProcedure

&AtClient
Procedure StartFillingWhenActivatingListOfApplications()
	
	UpdatedList_4();
	
EndProcedure

#Region Transfer

&AtClient
Procedure MovePaymentObjects(CommandName)
	
	PaymentsToBeTransferred = ThisObject[NameOfCurrentListOfTaggedEntries];
	
	If PaymentsToBeTransferred.Count() = 0 Then
			
		ClearMessages();
		MessageText = NStr("vi = 'Không có khoản thanh toán nào được chọn.';
							|ru = 'Не отмечено ни одного платежа.';
							|en = 'No payment is selected.'; fa = 'No payment is selected.';
							|it = 'No payment is selected.';
							|pl = 'No payment is selected.';
							|tr = 'Hiçbir ödeme işaretlenmemiş.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	If CommandName = "ToRight" Then
		
		PaymentDate = "+1";
		TransferPaymentItemsClient(PaymentsToBeTransferred, PaymentDate, Null);
		
	ElsIf CommandName = "ToEnd" Then
		
		PaymentDate = CashClientServer.PaymentDate(Object.PlanFromDate, Object.PlanningDays);
		TransferPaymentItemsClient(PaymentsToBeTransferred, PaymentDate, Null);
		
	ElsIf CommandName = "ToLeft" Then
		
		PaymentDate = "-1";
		TransferPaymentItemsClient(PaymentsToBeTransferred, PaymentDate, Null);
		
	ElsIf CommandName = "ToBeginning" Then
		
		TransferPaymentItemsClient(PaymentsToBeTransferred, Object.PlanFromDate, Null);
		
	ElsIf CommandName = "OnDate" Then
		
		CallbackDescription = New CallbackDescription("SwigApplicationsOnDate", ThisObject, PaymentsToBeTransferred);
		ToolTipText = NStr("vi = 'Chọn một ngày để chuyển thanh toán cho các đơn.';
							|ru = 'Выберите дату для переноса оплаты заявок.';
							|en = 'Select a date for request payment transfer.'; fa = 'Select a date for request payment transfer.';
							|it = 'Seleziona la data per il trasferimento delle richieste di pagamento.';
							|pl = 'Wybierz datę dla przeniesienia płatności zgłoszeń.';
							|tr = 'Başvurular için ödemeleri transfer etmek üzere tarih seç.'");
		
		ShowInputDate(CallbackDescription, Object.PlanFromDate, ToolTipText, DateFractions.Date);
		
	ElsIf CommandName = "ToAccount" Then
		
		CallbackDescription = New CallbackDescription("SwipingApplicationsToAccount", ThisObject, PaymentsToBeTransferred);
		ToolTipText = NStr("vi = 'Chọn một tài khoản ngân hàng để chuyển khoản thanh toán cho các đơn.';
							|ru = 'Выберите банковский счет для переноса оплаты заявок.';
							|en = 'Select a bank account for request payment transfer.'; fa = 'Select a bank account for request payment transfer.';
							|it = 'Selezionare il conto corrente per il trasferimento del pagamento delle richieste.';
							|pl = 'Wybierz rachunek bankowy dla przeniesienia płatności zgłoszeń.';
							|tr = 'Başvurular için ödemeleri transfer etmek üzere banka hesabını seç.'");
		
		AccountList = New ValueList;
		AccountList.LoadValues(BankAccountsCashAccountsAvailableForPaymentObject(PaymentsToBeTransferred));
		If AccountList.Count() Then
			AccountList.ShowChooseItem(CallbackDescription, ToolTipText);
		Else
			ClearMessages();
			MessageText = NStr("vi = 'Không có tài khoản có sẵn để phân bổ thanh toán.';
								|ru = 'Нет доступных счетов для распределения платежа.';
								|en = 'No available accounts for payment allocation.'; fa = 'No available accounts for payment allocation.';
								|it = 'Non ci sono fatture disponibili per la distribuzione dei pagamenti.';
								|pl = 'Brak dostępnych kont dla podziału płatności.';
								|tr = 'Ödemenin dağıtımı için erişilebilir hesaplar mevcut değil.'");
			CommonClient.MessageToUser(MessageText);
		EndIf;
		
	ElsIf CommandName = "Split" Then
		
		If PaymentsToBeTransferred.Count() > 1 Then
			
			ClearMessages();
			MessageText = NStr("vi = 'Chức năng phân chia thanh toán chỉ khả dụng cho một khoản thanh toán.';
								|ru = 'Разбиение оплаты доступно для одного платежа.';
								|en = 'Payment split is available for one payment.'; fa = 'Payment split is available for one payment.';
								|it = 'Payment split is available for one payment.';
								|pl = 'Payment split is available for one payment.';
								|tr = 'Ödemenin bölünmesi yalnızca tek bir ödeme için mümkündür.'");
			CommonClient.MessageToUser(MessageText);
		Else
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("RequestsToTransfer", PaymentsToBeTransferred);
			
			CallbackDescription = New CallbackDescription("ShiftingApplicationsWithPartitioning", ThisObject, AdditionalParameters);
			
			TheCurrentDataRow = Items[CurrentListName].CurrentData;
			
			If TheCurrentDataRow <> Undefined
				And TheCurrentDataRow.Property("BankAccountCashAccount")
				And TheCurrentDataRow.Property("Sum") Then
			
				FormParameters = New Structure;
				FormParameters.Insert("RequestsToTransfer", PaymentsToBeTransferred);
				FormParameters.Insert("BankAccountCashAccount", TheCurrentDataRow.BankAccountCashAccount);
				FormParameters.Insert("Sum", TheCurrentDataRow.Sum);
				FormParameters.Insert("Object", Object);
				
				OpenForm("DataProcessor.CashForecast.Form.PaymentSplit", FormParameters, ThisForm,,,,
					CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
		EndIf;
		
	ElsIf CommandName = "NotAllocated" Then
		
		PaymentDate = Date("00010101");
		TransferPaymentItemsClient(PaymentsToBeTransferred, PaymentDate, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SwigApplicationsOnDate(Result, RequestsToTransfer) Export
	
	If ValueIsFilled(Result) Then
		TransferPaymentItemsClient(RequestsToTransfer, Result, Null);
	EndIf;
	
EndProcedure

&AtClient
Procedure SwipingApplicationsToAccount(Result, RequestsToTransfer) Export
	
	If TypeOf(Result) = Type("ValueListItem") And ValueIsFilled(Result.Value) Then
		TransferPaymentItemsClient(RequestsToTransfer, Date("00010101"), Result.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftingApplicationsWithPartitioning(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		PaymentsToBeTransferred = New ValueList;
		PaymentsToBeTransferred.Add(AdditionalParameters.RequestsToTransfer[0].Value);
		
		TransferPaymentItemsClient(PaymentsToBeTransferred, AdditionalParameters.Date,
			AdditionalParameters.BankAccountCashAccount, , True, AdditionalParameters.Sum);
	EndIf;
	
EndProcedure

// Returns a table of checked entries in the current dynamic list
//
// Parameters:
//  PaymentTable_3 - DynamicList - The table in which you want to get the marked records.
//  TaggedEntries - ValueList of String - The list in which the IDs of the marked records will be placed.
//  IsWriteOff - Boolean - Indicates that you only need to receive write-offs
//  IsARequest - Boolean - A sign that you only need to receive an application for spending Cash
//
// Returns:
//  ValueTable - Table of flagged entries:
//		* PaymentObject - DefinedType.PaymentObject - Dimension of the payment schedule.
//		* BankAccountCashAccount - CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts - Dimension of the payment schedule.
//		* PaymentDate - Date - Dimension of the payment schedule.
//		* PayerBeneficiary - CatalogRef.Companies, CatalogRef.Counterparties, CatalogRef.Persons - Dimension of the payment schedule.
//		* Organization - CatalogRef.Companies - Dimension of the payment schedule.
//		* AmountType - EnumRef.LoanAndDepositScheduleAmountTypes, EnumRef.CashTransferKinds, EnumRef.TypesOfLeasePayments - Dimension of the payment schedule.
//		* ReceiptIssue - EnumRef.CashFlowTypes - Dimension of the payment schedule.
//		* Currency - CatalogRef.Currencies - Dimension of the payment schedule.
//		* Sum - DefinedType.MonetaryAmountNonNegative - A resource for PC payment schedules.
//		* Id - String - Payment payment system Attributes.
//		* Status - EnumRef.StatusesOfPaymentRequests - Payment payment system Attributes.
//		* OriginalBankAccountCashAccount - CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts - Payment payment system Attributes.
//		* PaymentDateOriginal - Date - Payment payment system Attributes.
//		* InitialAmount_ - DefinedType.MonetaryAmountNonNegative - Payment payment system Attributes.
//		* RequiredPaymentDate - Date - Document Attribute Link.The application for the use of monetary funds, a document link.Request a secondment.
//
&AtServerNoContext
Function TaggedEntries(PaymentTable_3, TaggedEntries, IsWriteOff = False, IsARequest = False)
	
	LineUp = AlignmentOfCurrentList(PaymentTable_3);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;
	
	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "BankAccountCashAccount");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentDate");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PayerBeneficiary");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Organization");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "AmountType");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "ReceiptIssue");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Currency");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Sum");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Id");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Status");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "OriginalBankAccountCashAccount");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentDateOriginal");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "InitialAmount_");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "RequiredPaymentDate");
	
	FinancialReportingServer.SetFilter(Settings.Filter, "Id", TaggedEntries);
		
	If IsWriteOff Then
		FinancialReportingServer.SetFilter(Settings.Filter, "IsWriteOff", True);
	EndIf;
	
	If IsARequest Then
		FinancialReportingServer.SetFilter(Settings.Filter, "IsARequest", True);
	EndIf;
	
	Return FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
EndFunction

&AtServerNoContext
Procedure GetLinesBalancesOnAccountsCashAccounts(AccountBalancesOfCashAccounts, TreeRow)
	
	If ValueIsFilled(TreeRow.BankAccountCashAccount) And Not ValueIsFilled(TreeRow.ReceiptIssue) Then
		NewRow = AccountBalancesOfCashAccounts.Add();
		FillPropertyValues(NewRow, TreeRow);
	EndIf;
	
	Rows = TreeRow.GetItems();
	
	For Each TreeStringIsChild In Rows Do
		GetLinesBalancesOnAccountsCashAccounts(AccountBalancesOfCashAccounts, TreeStringIsChild);
	EndDo;
	
EndProcedure

#EndRegion

#Region Drag

&AtClient
Procedure MarkedEntriesStartDragging(Item, DragParameters, Perform)
	
	PaymentsToDragAndDrop = ThisObject[NameOfCurrentListOfTaggedEntries];
	
	If PaymentsToDragAndDrop.Count() = 0 Then
		Perform = False;
	Else
		DragParameters.Value = PaymentsToDragAndDrop;
	EndIf;
	
	AvailableCheckoutAccounts = BankAccountsCashAccountsAvailableForPaymentObject(PaymentsToDragAndDrop);
	AvailableCheckoutAccounts.Add(Undefined);
	For Each TreeRow In Object.PaymentTree.GetItems() Do
		ChangeAccountAvailabilityFlag(TreeRow, AvailableCheckoutAccounts);
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeAccountAvailabilityFlag(TreeRow, AvailableCheckoutAccounts)
	
	TreeRow.AvailableForTransfer = (AvailableCheckoutAccounts.Find(TreeRow.BankAccountCashAccount) <> Undefined);
	
	For Each TreeRow In TreeRow.GetItems() Do
		ChangeAccountAvailabilityFlag(TreeRow, AvailableCheckoutAccounts);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function DayNumber(FieldName)
	
	DayNumber = 0;
	
	PosesOfDay = StrFind(FieldName, "Day");
	If PosesOfDay Then
		DayNumber = Number(Right(FieldName, StrLen(FieldName) - StrLen("Day") - PosesOfDay + 1));
	EndIf;
	
	Return DayNumber;
	
EndFunction

&AtClientAtServerNoContext
Function LongTermPeriodNumber(FieldName)
	
	PeriodNumber = 0;
	
	PeriodPoses = StrFind(FieldName, "LongTermPeriod");
	If PeriodPoses > 0 Then
		PeriodNumber = Number(Right(FieldName, StrLen(FieldName) - StrLen("LongTermPeriod") - PeriodPoses + 1));
	EndIf;
	
	Return PeriodNumber;
	
EndFunction

// Performs payment modification of operations.
// 
// Parameters:
//  PaymentItemsToBeTransferred - ValueList of String
//  PaymentDate - Date, Line.
//  BankAccountCashAccount - CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts - .
//  FlagClose - Boolean - Indicates that the "Close" commands have been executed.
//  ThisIsPartition - Boolean - Indicates whether the "Split payment" command has been executed.
//  AmountOfPartition - Number - The amount of the "Split payment" command.
//
&AtClient
Procedure TransferPaymentItemsClient(PaymentItemsToBeTransferred, PaymentDate, BankAccountCashAccount, FlagClose = False,
	ThisIsPartition = False, AmountOfPartition = 0)
	
	TimeConsumingOperation = TransferPaymentItemsServer(PaymentItemsToBeTransferred, PaymentDate, BankAccountCashAccount,
		FlagClose, ThisIsPartition, AmountOfPartition);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AtEndOfTransferOfPaymentObjects", ThisObject, PaymentDate);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtServer
Function TransferPaymentItemsServer(Val PaymentItemsToBeTransferred, PaymentDate, BankAccountCashAccount, FlagClose,
	ThisIsPartition, AmountOfPartition)
		
	If FlagClose Then
		
		TaggedEntries = TaggedEntries(Items[CurrentListName], PaymentItemsToBeTransferred, , True);
		
		If TaggedEntries.Count() = 0 Then
			Return DescribeResultOfErrorOfLongTermOperationOfOperation(
				NStr("vi = 'Không có giấy đề nghị chi tiền nào được chọn.';
					|ru = 'Не отмечено ни одной заявки на расходование денежных средств.';
					|en = 'No payment request is selected.'; fa = 'No payment request is selected.';
					|it = 'No payment request is selected.';
					|pl = 'No payment request is selected.';
					|tr = 'Hiçbir ödeme talebi işaretlenmemiş.'"));
		EndIf;
	Else
		TaggedEntries = TaggedEntries(Items[CurrentListName], PaymentItemsToBeTransferred);
	EndIf;
	
	TransferData = New Map;
	PrepareDataForTransferringPaymentObjects(TransferData, TaggedEntries, PaymentDate, BankAccountCashAccount,
		FlagClose, ThisIsPartition, AmountOfPartition);
	
	If Not TransferData.Count() Then
		Return DescribeResultOfErrorOfLongTermOperationOfOperation(NStr("vi = 'Không thể xử lý các khoản thanh toán theo kế hoạch.';
																		|ru = 'Не удалось обработать плановые платежи.';
																		|en = 'Cannot process scheduled payments.'; fa = 'Cannot process scheduled payments.';
																		|it = 'Cannot process scheduled payments.';
																		|pl = 'Cannot process scheduled payments.';
																		|tr = 'Planlı ödemeler işlenemedi.'"));
	EndIf;
	
	JobDescription = NStr("vi = 'Chuyển các đối tượng thanh toán';
							|ru = 'Перенос объектов оплаты';
							|en = 'Payment object transfer'; fa = 'Payment object transfer';
							|it = 'Payment object transfer';
							|pl = 'Payment object transfer';
							|tr = 'Ödeme nesnelerinin taşınması'");
	MethodToExecute = "DataProcessors.CashForecast.TransferPaymentItems";
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TransferData", TransferData);
	ParametersStructure.Insert("PlanFromDate", Object.PlanFromDate);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	If TransferData.Count() = 1 Then
		ExecutionParameters.RunNotInBackground1 = True;
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);
	
EndFunction

&AtClient
Procedure AtEndOfTransferOfPaymentObjects(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ClearMessages();
		CommonClient.MessageToUser(Result.BriefErrorDescription);
		Return;
	EndIf;
	
	AtEndOfTransferOfPaymentObjectsAtServer(Result.ResultAddress, AdditionalParameters);
	ManagingHistoryElements();
	
EndProcedure

&AtServer
Procedure AtEndOfTransferOfPaymentObjectsAtServer(ResultAddress, AdditionalParameters)
	
	TransferredApplications = GetFromTempStorage(ResultAddress);
	If TransferredApplications.Count() Then
		ReflectTransferResultInPaymentTree(TransferredApplications);
		If AdditionalParameters <> Date("00010101") Then
			RecordChangeHistory(TransferredApplications);
		EndIf;
		CurFormList = Items[CurrentListName]; // FormTable
		CurFormList.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Function CancelRepeatOperationOnServer(Changes)
	
	JobDescription = NStr("vi = 'Chuyển các đối tượng thanh toán';
							|ru = 'Перенос объектов оплаты';
							|en = 'Payment object transfer'; fa = 'Payment object transfer';
							|it = 'Payment object transfer';
							|pl = 'Payment object transfer';
							|tr = 'Ödeme nesnelerinin taşınması'");
	MethodToExecute = "DataProcessors.CashForecast.TransferPaymentItems";
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TransferData", Changes);
	ParametersStructure.Insert("PlanFromDate", Object.PlanFromDate);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	If Changes.Count() = 1 Then
		ExecutionParameters.RunNotInBackground1 = True;
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);
	
EndFunction

&AtClient
Procedure WhenCompletingUndoRedoOperation(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Return;
	EndIf;
	
	WhenCompletingUndoRedoOperationOnServer(Result.ResultAddress);
	ManagingHistoryElements();
	
EndProcedure

&AtServer
Procedure WhenCompletingUndoRedoOperationOnServer(ResultAddress)
	
	TransferredApplications = GetFromTempStorage(ResultAddress);
	ReflectTransferResultInPaymentTree(TransferredApplications);
	CurFormList = Items[CurrentListName]; // FormTable
	CurFormList.Refresh();
	
EndProcedure

&AtServerNoContext
Procedure PrepareDataForTransferringPaymentObjects(TransferData, PaymentItemsToBeTransferred, PaymentDate, BankAccountCashAccount,
	FlagClose, ThisIsPartition, AmountOfPartition)
	
	For Each ObjectToTransfer In PaymentItemsToBeTransferred Do
		
		TransferStructure = DataProcessors.CashForecast.TransferStructure();
			
		FillPropertyValues(TransferStructure, ObjectToTransfer);
		
		If Not AmountOfPartition = 0 Then
			TransferStructure.TransferAmount_ = AmountOfPartition;
		ElsIf ObjectToTransfer.Sum < 0 Then
			TransferStructure.TransferAmount_ = -ObjectToTransfer.Sum;
		Else
			TransferStructure.TransferAmount_ = ObjectToTransfer.Sum;
		EndIf;
		TransferStructure.ThisIsPartition = ThisIsPartition;
		PaymentObject = ?(TypeOf(ObjectToTransfer.PaymentObject) = Type("DocumentRef.PaymentRequest"),
			ObjectToTransfer.PaymentObject, ObjectToTransfer.Id);
		
		If ValueIsFilled(TransferStructure.BankAccountCashAccount) Then
			TransferStructure.TransferCurrency_ =
				Common.ObjectAttributeValue(TransferStructure.BankAccountCashAccount, "CashCurrency");
		Else
			TransferStructure.TransferCurrency_ = TransferStructure.Currency;
		EndIf;
		
		PaymentObjectTransferData = TransferData.Get(PaymentObject);
		If PaymentObjectTransferData = Undefined Then
			PaymentObjectTransferData = New Array;
		EndIf;
		
		TransferStructure.ZoomRatio = 1;
		PaymentObjectTransferData.Add(TransferStructure);
		
		If FlagClose Then
			TransferStructure.FlagClose = True;
		Else
			TransferStructure.FlagClose = False;
			StructureOfKohTransfer = DataProcessors.CashForecast.TransferStructure();
			FillPropertyValues(StructureOfKohTransfer, TransferStructure);
			StructureOfKohTransfer.ZoomRatio = -1;
			
			If PaymentDate = "+1" Then
				StructureOfKohTransfer.PaymentDate = CashClientServer.PaymentDate(TransferStructure.PaymentDate, 2);
			ElsIf PaymentDate = "-1" Then
				StructureOfKohTransfer.PaymentDate = CashClientServer.PaymentDate(TransferStructure.PaymentDate, 0);
			Else
				If ValueIsFilled(PaymentDate) Then
					StructureOfKohTransfer.PaymentDate = PaymentDate;
				Else
					StructureOfKohTransfer.PaymentDate =
						?(TypeOf(PaymentObject) = Type("DocumentRef.PaymentRequest"),
							ObjectToTransfer.PaymentDate, PaymentDate);
				EndIf;
				If BankAccountCashAccount <> Null Then
					StructureOfKohTransfer.BankAccountCashAccount = BankAccountCashAccount;
				EndIf;
			EndIf;
			
			If ValueIsFilled(StructureOfKohTransfer.BankAccountCashAccount) Then
				StructureOfKohTransfer.TransferCurrency_ =
					Common.ObjectAttributeValue(StructureOfKohTransfer.BankAccountCashAccount, "CashCurrency");
			Else
				StructureOfKohTransfer.TransferCurrency_ = StructureOfKohTransfer.Currency;
			EndIf;
			
			PaymentObjectTransferData.Add(StructureOfKohTransfer);
		EndIf;
		
		TransferData.Insert(PaymentObject, PaymentObjectTransferData);
	EndDo;
	
EndProcedure

&AtServer
Function DistributeAtServer(TaggedEntries)
	
	PaymentObjectsToBeDistributed = TaggedEntries(Items[CurrentListName], TaggedEntries, True);
	
	If PaymentObjectsToBeDistributed.Count() = 0 Then
		Return DescribeResultOfErrorOfLongTermOperationOfOperation(NStr("vi = 'Không có khoản ghi giảm nào được chọn.';
																		|ru = 'Не отмечено ни одного списания.';
																		|en = 'No outgoing payment is selected.'; fa = 'No outgoing payment is selected.';
																		|it = 'No outgoing payment is selected.';
																		|pl = 'No outgoing payment is selected.';
																		|tr = 'Hiçbir gider yazma işaretlenmemiş.'"));
	EndIf;
	
	AccountBalancesOfCashAccounts = New ValueTable;
	AccountBalancesOfCashAccounts.Columns.Add("BankAccountCashAccount");
	AccountBalancesOfCashAccounts.Columns.Add("Currency");
	For Indus = 1 To Object.PlanningDays Do
		AccountBalancesOfCashAccounts.Columns.Add("Day" + Indus);
	EndDo;
	
	TreeRows = Object.PaymentTree.GetItems();
	For Each TreeRow In TreeRows Do
		GetLinesBalancesOnAccountsCashAccounts(AccountBalancesOfCashAccounts, TreeRow);
	EndDo;
	
	DistributionData = New Map;
	PrepareDataOnDistributionOfPaymentObjects(DistributionData, PaymentObjectsToBeDistributed, AccountBalancesOfCashAccounts,
		Object.PlanFromDate, Object.PlanningDays);
		
	JobDescription = NStr("vi = 'Phân bổ các đối tượng thanh toán';
							|ru = 'Распределение объектов оплаты';
							|en = 'Payment object allocation'; fa = 'Payment object allocation';
							|it = 'Payment object allocation';
							|pl = 'Payment object allocation';
							|tr = 'Ödeme nesnelerinin dağıtımı'");
	MethodToExecute = "DataProcessors.CashForecast.TransferPaymentItems";
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TransferData", DistributionData);
	ParametersStructure.Insert("PlanFromDate", Object.PlanFromDate);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	If DistributionData.Count() = 1 Then
		ExecutionParameters.RunNotInBackground1 = True;
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);
	
EndFunction

&AtServer
Procedure RecordChangeHistory(TransferredApplications)
	
	If Not TransferredApplications.Count() Then
		Return;
	EndIf;
	
	While ChangeHistory.Count() > CurrentHistoryIndex Do
		ChangeHistory.Delete(ChangeHistory.Count() - 1);
	EndDo;
	
	ChangeHistory.Add(TransferredApplications);
	CurrentHistoryIndex = CurrentHistoryIndex + 1;
	If ChangeHistory.Count() > 100 Then
		ChangeHistory.Delete(0);
		CurrentHistoryIndex = CurrentHistoryIndex - 1;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReflectTransferResultInPaymentTree(TransferredApplications)
	
	UpdateCalendar = False;
	TreeRows = Object.PaymentTree.GetItems();
	For Each PaymentObject In TransferredApplications Do
		For Each TransferStructure In PaymentObject.Value Do
			IsFoundStringTurnover = False;
			For Each TreeRow In TreeRows Do
				CalculateCarryInTreeRows(TreeRow, TransferStructure, IsFoundStringTurnover);
			EndDo;
			If Not IsFoundStringTurnover Then
				If ValueIsFilled(TransferStructure.BankAccountCashAccount) Then
					CreateChargeLine(TransferStructure);
				Else
					UpdateCalendar = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If TransferredApplications.Count() Then
		For Each TreeRow In TreeRows Do
			CashClientServer.RecalculateSubordinateTreeRows(TreeRow, Object.PlanningDays);
			DataProcessors.CashForecast.RecalculateLongTermPeriodsInSubordinateRowsOfTree(TreeRow,
				Object.LongTermPlanningPeriods, Object.PlanningDays);
		EndDo;
	EndIf;
	
	If UpdateCalendar Then
		UpdateListsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateCarryInTreeRows(TreeRow, TransferStructure, IsFoundStringTurnover = True)

	If TransferStructure.PaymentDate > Object.EndDate Then
		Return;
	EndIf;
	
	ThisIsLongTermColumn = False;
	If TransferStructure.PaymentDate > Object.EndDateOfPlanningByDay Then
		LineLongTermPeriod = LongTermPeriodByPaymentDate(TransferStructure.PaymentDate, LongTermPeriods);
		ThisIsLongTermColumn = (LineLongTermPeriod <> Undefined);
	EndIf;
	
	If ThisIsLongTermColumn Then
		PaymentDay = Undefined;
		ColumnName = "LongTermPeriod" + LineLongTermPeriod.Number;
	Else
		PaymentDay = CashClientServer.PaymentDay(Object.PlanFromDate, TransferStructure.PaymentDate);
		ColumnName = "Day" + PaymentDay;
	EndIf;
	
	WriteOffType = Enums.CashFlowTypes.WriteOff;
	Process = False;
	RateOfConversion = 1;
	
	// Turnover in currency
	If TreeRow.LineKind = 1
		And TreeRow.ReceiptIssue = WriteOffType Then
		
		If TypeOf(TreeRow.Group) = Type("String")
			And TreeRow.UnallocatedLine Then
			
			Process = (TreeRow.BankAccountCashAccount = TransferStructure.BankAccountCashAccount)
				And (TreeRow.Currency = TransferStructure.Currency);
			
		ElsIf ValueIsFilled(TreeRow.BankAccountCashAccount) Then
			Process = (TreeRow.BankAccountCashAccount = TransferStructure.BankAccountCashAccount);
		Else
			Process = (TreeRow.Currency = TransferStructure.TransferCurrency_);
		EndIf;
		
		If Process Then
			If ValueIsFilled(TreeRow.Currency) And TreeRow.Currency <> TransferStructure.Currency Then
				RateOfConversion = CashCached.RateOfConversion(
					TransferStructure.Currency, TreeRow.Currency, Object.PlanFromDate);
			EndIf;
			TransferAmount_ = Round(TransferStructure.TransferAmount_ * TransferStructure.ZoomRatio * RateOfConversion, 2);
			
			TreeRow[ColumnName + "InCurrency"] = TreeRow[ColumnName + "InCurrency"] + TransferAmount_;
			TreeRow.Sum = TreeRow.Sum + TransferAmount_;
			
			If PaymentDay = 0 Then
				TreeRow.Overdue = TreeRow.Overdue + TransferAmount_;
			EndIf;
			
			If ValueIsFilled(TransferStructure.BankAccountCashAccount) Then
				IsFoundStringTurnover = IsFoundStringTurnover Or ValueIsFilled(TreeRow.BankAccountCashAccount);
			Else
				IsFoundStringTurnover = IsFoundStringTurnover Or (TypeOf(TreeRow.Group) = Type("String"));
			EndIf;
		EndIf;
		
	// Turnover in one currency
	ElsIf TreeRow.LineKind = 3
		And TreeRow.ReceiptIssue = WriteOffType Then
		
		If ValueIsFilled(TransferStructure.BankAccountCashAccount)
			And TypeOf(TreeRow.Group) = Type("String")
			And TreeRow.UnallocatedLine Then
			Process = False;
		Else
			Process = True;
		EndIf;
		
		If Process Then
			If Object.TotalCurrency <> TransferStructure.Currency Then
				RateOfConversion = CashCached.RateOfConversion(
					TransferStructure.Currency, Object.TotalCurrency, Object.PlanFromDate);
			EndIf;
			TransferAmount_ = Round(TransferStructure.TransferAmount_ * TransferStructure.ZoomRatio * RateOfConversion, 2);
			
			TreeRow[ColumnName + "InOneCurrency"] = TreeRow[ColumnName + "InOneCurrency"] + TransferAmount_;
			TreeRow.Sum = TreeRow.Sum + TransferAmount_;
			
			If PaymentDay = 0 Then
				TreeRow.OverdueInOneCurrency = TreeRow.OverdueInOneCurrency + TransferAmount_;
			EndIf;
		EndIf;
			
	// Currency balances
	ElsIf TreeRow.LineKind = 0 Then
		
		If ValueIsFilled(TreeRow.BankAccountCashAccount) Then
			Process = (TreeRow.BankAccountCashAccount = TransferStructure.BankAccountCashAccount);
		Else
			Process = (TreeRow.Currency = TransferStructure.TransferCurrency_);
		EndIf;
		
		If Process Then
			If ValueIsFilled(TreeRow.Currency) And TreeRow.Currency <> TransferStructure.Currency Then
				RateOfConversion = CashCached.RateOfConversion(
					TransferStructure.Currency, TreeRow.Currency, Object.PlanFromDate);
			EndIf;
			TransferAmount_ = Round(TransferStructure.TransferAmount_ * TransferStructure.ZoomRatio * RateOfConversion, 2);
			
			TreeRow[ColumnName + "InCurrency"] = TreeRow[ColumnName + "InCurrency"] + TransferAmount_;
			TreeRow.Sum = TreeRow.Sum + TransferAmount_;
			
			If PaymentDay = 0 Then
				TreeRow.Overdue = TreeRow.Overdue + TransferAmount_;
			EndIf;
		EndIf;
		
	// Balances in one currency
	ElsIf TreeRow.LineKind = 2 Then
		
		Process = (TreeRow.Currency = TransferStructure.TransferCurrency_) Or Not ValueIsFilled(TreeRow.Currency);
		
		If Process Then
			If Object.TotalCurrency <> TransferStructure.Currency Then
				RateOfConversion = CashCached.RateOfConversion(
					TransferStructure.Currency, Object.TotalCurrency, Object.PlanFromDate);
			EndIf;
			TransferAmount_ = Round(TransferStructure.TransferAmount_ * TransferStructure.ZoomRatio * RateOfConversion, 2);
			
			TreeRow[ColumnName + "InOneCurrency"] = TreeRow[ColumnName + "InOneCurrency"] + TransferAmount_;
			TreeRow.Sum = TreeRow.Sum + TransferAmount_;
			
			If PaymentDay = 0 Then
				TreeRow.OverdueInOneCurrency = TreeRow.OverdueInOneCurrency + TransferAmount_;
			EndIf;
		EndIf;
	EndIf;
	
	For Each TreeRow In TreeRow.GetItems() Do
		CalculateCarryInTreeRows(TreeRow, TransferStructure, IsFoundStringTurnover);
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateChargeLine(RowData)
	
	PaymentDay = CashClientServer.PaymentDay(Object.PlanFromDate, RowData.PaymentDate);
	
	If PaymentDay > Object.PlanningDays Then
		Return;
	EndIf;
	
	BankAccountCashAccount = RowData.BankAccountCashAccount;
	
	InvoiceLine_ = FinancialReportingServer.SubordinateItem(Object.PaymentTree, "Group", BankAccountCashAccount);
	If InvoiceLine_ <> Undefined Then
		
		NewRow = InvoiceLine_.GetItems().Add();
		NewRow.BankAccountCashAccount = BankAccountCashAccount;
		NewRow.ReceiptIssue = Enums.CashFlowTypes.WriteOff;
		NewRow.Group         = Enums.CashFlowTypes.WriteOff;
		NewRow.LineKind           = 1;
		
		CashCurrency = Common.ObjectAttributeValue(BankAccountCashAccount, "CashCurrency");
		NewRow.Currency = CashCurrency;
		
		RateOfConversion = 1;
		If CashCurrency <> RowData.Currency Then
			RateOfConversion = CashCached.RateOfConversion(
				RowData.Currency, CashCurrency, Object.PlanFromDate);
		EndIf;
		
		NewRow["Day" + PaymentDay + "InCurrency"] = RowData.TransferAmount_ * RowData.ZoomRatio * RateOfConversion;
	EndIf;
	
EndProcedure

&AtServer
Procedure PrepareDataOnDistributionOfPaymentObjects(DistributionData, PaymentObjectsToBeDistributed,
	AccountBalancesOfCashAccounts, PlanFromDate, PlanningDays)
	
	Requests = New Array;
	DeleteRows_ = New Array;
	
	For Each Payment_ In PaymentObjectsToBeDistributed Do
			
		If ValueIsFilled(Payment_.BankAccountCashAccount) Then
			
			Common.MessageToUser(
				StrTemplate(NStr("vi = 'Không thể phân bổ thanh toán cho đối tượng thanh toán %1. %2';
								|ru = 'Не удалось распределить оплату объекта оплаты %1. %2';
								|en = 'Cannot allocate the %1 payment. %2'; fa = 'Cannot allocate the %1 payment. %2';
								|it = 'Cannot allocate the %1 payment. %2';
								|pl = 'Cannot allocate the %1 payment. %2';
								|tr = '%1 ödeme nesnesi için ödeme dağıtılamadı. %2'"),
					Payment_.PaymentObject, NStr("vi = 'Tài khoản ngân hàng / Quỹ tiền mặt đã được điền.';
												|ru = 'Уже заполнен Банковский счет / Касса.';
												|en = 'Bank / cash account is already filled in.'; fa = 'Bank / cash account is already filled in.';
												|it = 'Bank / cash account is already filled in.';
												|pl = 'Bank / cash account is already filled in.';
												|tr = 'Banka hesabı / Kasa hesabı zaten doldurulmuş.'")));
			DeleteRows_.Add(Payment_);
			Continue;
		EndIf;
		
		DistributionKey = ?(TypeOf(Payment_.PaymentObject) = Type("DocumentRef.PaymentRequest"),
			Payment_.PaymentObject, Payment_.Id);
		
		PaymentObjectTransferData = DistributionData.Get(DistributionKey);
		If PaymentObjectTransferData = Undefined Then
			PaymentObjectTransferData = New Array;
		EndIf;
		
		TransferStructure = DataProcessors.CashForecast.TransferStructure();
		FillPropertyValues(TransferStructure, Payment_);
		TransferStructure.TransferCurrency_ = Payment_.Currency;

		TransferStructure.TransferAmount_ = ?(Payment_.Sum < 0, -Payment_.Sum, Payment_.Sum);
		
		TransferStructure.ZoomRatio = 1;
		TransferStructure.FlagClose = False;
		PaymentObjectTransferData.Add(TransferStructure);
		
		DistributionData.Insert(DistributionKey, PaymentObjectTransferData);
		
		If TypeOf(Payment_.PaymentObject) = Type("DocumentRef.PaymentRequest") Then
			Requests.Add(Payment_.PaymentObject);
		EndIf;
	EndDo;
	
	For Each DeleteLine In DeleteRows_ Do
		PaymentObjectsToBeDistributed.Delete(DeleteLine);
	EndDo;
	
	PaymentIds = New ValueList;
	For Each Payment_ In PaymentObjectsToBeDistributed Do
		PaymentIds.Add(Payment_.Id);
	EndDo;
	
	AttributesList = "Ref, BankAccount, CashAccount";
	DetailsOfApplications = Common.ObjectsAttributesValues(Requests, AttributesList); // Map
	
	CheckoutBankAccountValues = BankAccountsCashAccountsAvailableForPaymentObject(PaymentIds, False);
	
	For Each Payment_ In PaymentObjectsToBeDistributed Do
		
		IsARequest = (TypeOf(Payment_.PaymentObject) = Type("DocumentRef.PaymentRequest"));
		
		AttributesOfApplication = ?(IsARequest, DetailsOfApplications.Get(Payment_.PaymentObject), Undefined);
		DistributionKey = ?(IsARequest, Payment_.PaymentObject, Payment_.Id);
		
		PaymentDay = CashClientServer.PaymentDay(PlanFromDate,
			Payment_.RequiredPaymentDate);
		If PaymentDay > (PlanningDays + 1) Then
			Common.MessageToUser(
				StrTemplate(NStr("vi = 'Không thể phân bổ thanh toán cho đối tượng thanh toán %1. %2';
								|ru = 'Не удалось распределить оплату объекта оплаты %1. %2';
								|en = 'Cannot allocate the %1 payment. %2'; fa = 'Cannot allocate the %1 payment. %2';
								|it = 'Cannot allocate the %1 payment. %2';
								|pl = 'Cannot allocate the %1 payment. %2';
								|tr = '%1 ödeme nesnesi için ödeme dağıtılamadı. %2'"),
					Payment_.PaymentObject, NStr("vi = 'Ngày thanh toán vượt quá ngày kết thúc lập kế hoạch theo ngày.';
												|ru = 'Дата платежа превышает дату окончания планирования по дням.';
												|en = 'The payment date exceeds the planning end date by days.'; fa = 'The payment date exceeds the planning end date by days.';
												|it = 'The payment date exceeds the planning end date by days.';
												|pl = 'The payment date exceeds the planning end date by days.';
												|tr = 'Ödeme tarihi, günlere göre planlama bitiş tarihini aşıyor.'")));
			Continue;
		EndIf;
		
		ApplicationDistributionData = DistributionData.Get(DistributionKey);
		DistributionStructure = ApplicationDistributionData[0];
		
		DesirableBankAccountCashRegister = Undefined;
		If IsARequest Then
			If ValueIsFilled(AttributesOfApplication.BankAccount) Then
				DesirableBankAccountCashRegister = AttributesOfApplication.BankAccount;
			ElsIf ValueIsFilled(AttributesOfApplication.CashAccount) Then
				DesirableBankAccountCashRegister = AttributesOfApplication.CashAccount;
			EndIf;
		EndIf;
		
		If DesirableBankAccountCashRegister <> Undefined Then
			FoundRows = AccountBalancesOfCashAccounts.FindRows(New Structure("BankAccountCashAccount",
				DesirableBankAccountCashRegister));
			If FoundRows.Count() Then
				FirstAccount = AccountBalancesOfCashAccounts.Find(FoundRows[0].BankAccountCashAccount);
				If FirstAccount <> Undefined Then
					RowIndex = AccountBalancesOfCashAccounts.IndexOf(FirstAccount);
					AccountBalancesOfCashAccounts.Move(RowIndex, -RowIndex);
				EndIf;
			EndIf;
		EndIf;
		
		If TypeOf(CheckoutBankAccountValues) = Type("Map") Then
		
			AvailableBankAccounts = CheckoutBankAccountValues.Get(DistributionKey);
		Else
			AvailableBankAccounts = Undefined;
		EndIf;
		
		If AvailableBankAccounts = Undefined Then
			CancelDistributionOfPaymentObject(DistributionData, Payment_.PaymentObject,
				NStr("vi = 'Không tìm thấy Tài khoản ngân hàng / Quỹ tiền mặt khả dụng nào.';
					|ru = 'Не подобран доступный Банковский счет / Касса.';
					|en = 'An available bank / cash account is not picked.'; fa = 'An available bank / cash account is not picked.';
					|it = 'An available bank / cash account is not picked.';
					|pl = 'An available bank / cash account is not picked.';
					|tr = 'Uygun Banka hesabı / Kasa hesabı seçilmemiş.'"));
			Continue;
		EndIf;
		
		RemainsToPay = DistributionStructure.TransferAmount_;
		PayForPaymentObjectUsingPaymentTree(ApplicationDistributionData, RemainsToPay, AvailableBankAccounts,
			AccountBalancesOfCashAccounts, PlanFromDate, PlanningDays);
		
		DistributionAmount_ = 0;
		For Each DistributionString In ApplicationDistributionData Do
			DistributionAmount_ = DistributionAmount_ + DistributionString.TransferAmount_ * DistributionString.ZoomRatio;
		EndDo;
		If DistributionAmount_ Then
			CancelDistributionOfPaymentObject(DistributionData, Payment_.PaymentObject,
				NStr("vi = 'Không đủ số dư.';
					|ru = 'Недостаточно остатков.';
					|en = 'Insufficient balance.'; fa = 'Insufficient balance.';
					|it = 'Insufficient balance.';
					|pl = 'Insufficient balance.';
					|tr = 'Yetersiz bakiye.'"));
		EndIf;
	EndDo;
	
EndProcedure

// Cancels the distribution of the payment object by deleting it from the distribution data
// 
// Parameters:
//  DistributionData - Map of KeyAndValue - The selected rows for distribution, 
//                        where the key is the type being determined.Objectpayments - an application for spending DS from the list of applications,
//                        The value is an array from the Structure- data for the application from the payment schedule.
//  Request - InformationRegisterRecordKey.ScheduleOfPayments - a line from the list of applications.
//  ErrorReason - String
//
&AtServer
Procedure CancelDistributionOfPaymentObject(DistributionData, Request, ErrorReason = "")
	
	DistributionData.Delete(Request);
	Common.MessageToUser(
		StrTemplate(NStr("vi = 'Không thể phân chia khoản thanh toán của chứng từ %1. %2';
						|ru = 'Не удалось распределить оплату документа %1. %2';
						|en = 'Cannot allocate the %1 document payment. %2'; fa = 'Cannot allocate the %1 document payment. %2';
						|it = 'Cannot allocate the %1 document payment. %2';
						|pl = 'Cannot allocate the %1 document payment. %2';
						|tr = '%1 belgesi için ödeme dağıtılamadı. %2'"), Request, ErrorReason),
		Request);
	
EndProcedure

&AtServer
Procedure PayForPaymentObjectUsingPaymentTree(ApplicationDistributionData, RemainsToPay, AvailableBankAccounts,
	RemainderLines_, PlanFromDate, PlanningDays)
	
	DistributionStructure = ApplicationDistributionData[0];
	
	MinimumDayOfPayment = 0;
	
	For Indus = 1 To PlanningDays Do
		
		DayOfVerification = PlanningDays - Indus + 1;
		TotalAvailableByInvoicePerDay = 0;
		
		For Each RemainderLine_ In RemainderLines_ Do
			
			If AvailableBankAccounts.Find(RemainderLine_.BankAccountCashAccount) = Undefined Then
				Continue;
			EndIf;
			
			RateOfConversion = 1;
			If ValueIsFilled(RemainderLine_.Currency) And RemainderLine_.Currency <> DistributionStructure.Currency Then
				RateOfConversion = CashCached.RateOfConversion(
					RemainderLine_.Currency, DistributionStructure.Currency, PlanFromDate);
			EndIf;
			
			If RemainderLine_["Day" + DayOfVerification] > 0 Then
				TotalAvailableByInvoicePerDay = TotalAvailableByInvoicePerDay + RemainderLine_["Day" + DayOfVerification]
					* RateOfConversion;
			EndIf;
			
			If TotalAvailableByInvoicePerDay >= RemainsToPay Then
				MinimumDayOfPayment = DayOfVerification;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If Not MinimumDayOfPayment Then
		Return;
	EndIf;
	
	MinimumPaymentDate = CashClientServer.PaymentDate(PlanFromDate, MinimumDayOfPayment);
	EstimatedPaymentDate = Max(MinimumPaymentDate, DistributionStructure.PaymentDate);
	
	For Each RemainderLine_ In RemainderLines_ Do
		
		If AvailableBankAccounts.Find(RemainderLine_.BankAccountCashAccount) = Undefined Then
			Continue;
		EndIf;
		
		RateOfConversion = 1;
		If ValueIsFilled(RemainderLine_.Currency) And RemainderLine_.Currency <> DistributionStructure.Currency Then
			RateOfConversion = CashCached.RateOfConversion(
				DistributionStructure.Currency, RemainderLine_.Currency, PlanFromDate);
		EndIf;
		
		PayFromAccount = Min(RemainderLine_["Day" + MinimumDayOfPayment], RemainsToPay * RateOfConversion);
		
		If PayFromAccount <= 0 Then
			Continue;
		EndIf;
		
		RemainderLine_["Day" + MinimumDayOfPayment] = RemainderLine_["Day" + MinimumDayOfPayment] - PayFromAccount;
		RemainsToPay = RemainsToPay - PayFromAccount / RateOfConversion;
		
		TransferStructure = DataProcessors.CashForecast.TransferStructure();
		TransferStructure.BankAccountCashAccount = RemainderLine_.BankAccountCashAccount;
		TransferStructure.PaymentDate = EstimatedPaymentDate;
		TransferStructure.Currency = DistributionStructure.Currency;
		TransferStructure.TransferCurrency_ = RemainderLine_.Currency;
		TransferStructure.TransferAmount_ = PayFromAccount / RateOfConversion;
		TransferStructure.ZoomRatio = -1;
		TransferStructure.FlagClose = False;
		TransferStructure.PaymentObject = DistributionStructure.PaymentObject;
		ApplicationDistributionData.Add(TransferStructure);
		
		If Not RemainsToPay Then
			Break;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

&AtClient
Function LineCanBeShifted(Direction)
	
	CurrentData = Items.PaymentTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	If TypeOf(CurrentData.Group) <> Type("CatalogRef.CompaniesBankAccounts")
		And TypeOf(CurrentData.Group) <> Type("CatalogRef.CashAccounts") Then
		Return False;
	EndIf;
	
	Parent = CurrentData.GetParent();
	If Parent = Undefined Then
		AccountLevelElements = Object.PaymentTree.GetItems();
	Else
		AccountLevelElements = Parent.GetItems();
	EndIf;
	
	RowIndex = AccountLevelElements.IndexOf(CurrentData);
	NewIndexOfRow = RowIndex + Direction;
	
	If NewIndexOfRow < 0 Or NewIndexOfRow > AccountLevelElements.Count() - 1 Then
		Return False;
	EndIf;
	
	ReplacementData = AccountLevelElements.Get(NewIndexOfRow);
	
	If TypeOf(ReplacementData.Group) <> Type("CatalogRef.CompaniesBankAccounts")
		And TypeOf(ReplacementData.Group) <> Type("CatalogRef.CashAccounts") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure ShiftLine(Direction)
	
	CurrentRow = Items.PaymentTree.CurrentRow;
	CurrentData = Object.PaymentTree.FindByID(CurrentRow);
	
	Parent = CurrentData.GetParent();
	If Parent = Undefined Then
		AccountLevelElements = Object.PaymentTree.GetItems();
	Else
		AccountLevelElements = Parent.GetItems();
	EndIf;
	
	AccountLevelElements.Move(AccountLevelElements.IndexOf(CurrentData), Direction);
	
	RecordSet = InformationRegisters.CashForecastProcedure.CreateRecordSet();
	RecordSet.Fill(Undefined);
	SetTable = RecordSet.Unload();
	
	For Each TreeRow In AccountLevelElements Do
		
		If Not ValueIsFilled(TreeRow.BankAccountCashAccount) Then
			Continue;
		EndIf;
		
		NewRow = SetTable.Add();
		NewRow.BankAccountCashAccount = TreeRow.BankAccountCashAccount;
		NewRow.OrderValue = AccountLevelElements.IndexOf(TreeRow);
	EndDo;
	
	For Each TableRow In SetTable Do
		Record = InformationRegisters.CashForecastProcedure.CreateRecordManager();
		Record.Fill(Undefined);
		FillPropertyValues(Record, TableRow);
		Record.Write(True);
	EndDo;
	
EndProcedure

&AtClient
Procedure ManagingHistoryElements()
	
	Items.CancelOperation.Enabled = (CurrentHistoryIndex > 0);
	Items.RepeatOperation.Enabled = (CurrentHistoryIndex < ChangeHistory.Count());
	
EndProcedure

&AtClientAtServerNoContext
Function FilterPresentation(List)
	
	Presentation = "";
	For Each ListItem In List Do
		If ListItem.Check Then
			ItemPresentation = ?(ValueIsFilled(ListItem.Presentation), ListItem.Presentation, ListItem.Value);
			Presentation = Presentation + ?(ValueIsFilled(Presentation), ", ", "") + ItemPresentation;
		EndIf;
	EndDo;
	
	Return Presentation;
	
EndFunction

&AtServerNoContext
Function BankAccountsCashAccountsAvailableForPaymentObject(PaymentsToBeTransferred, Exceptional = True)
	
	Return DataProcessors.CashForecast.BankAccountsCashAccountsAvailableForPaymentObject(PaymentsToBeTransferred, Exceptional);
	
EndFunction

&AtServer
Procedure FillInListOfCheckoutInvoicesOnServer()
	
	Companies = New Array;
	For Each FilterElement In Object.FilterCompanies Do
		If FilterElement.Check Then
			Companies.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	BankAccountsCashAccounts = New Array;
	For Each FilterElement In Object.FilterBankAccountsCashAccounts Do
		If FilterElement.Check Then
			BankAccountsCashAccounts.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	CatalogData.Ref,
	|	CatalogData.Description AS Description,
	|	1 AS OrderField_
	|INTO CashAccountingObjects
	|FROM
	|	Catalog.CompaniesBankAccounts AS CatalogData
	|	INNER JOIN Catalog.Companies AS Companies
	|	ON Companies.Ref = CatalogData.Owner
	|	
	|WHERE
	|	NOT CatalogData.DeletionMark
	|	AND NOT CatalogData.Closed
	|	AND (&YouDonTNeedToSelectOrganizations
	|			OR CatalogData.Owner IN (&Companies))
	|	AND (&NoCurrencySelectionNeeded
	|			OR CatalogData.CashCurrency = &Currency)
	|
	|UNION ALL
	|
	|SELECT
	|	CatalogData.Ref,
	|	CatalogData.Description,
	|	1 AS OrderField_
	|FROM
	|	Catalog.CashAccounts AS CatalogData
	|	INNER JOIN Catalog.Companies AS Companies
	|	ON Companies.Ref = CatalogData.Owner
	|	
	|WHERE
	|	NOT CatalogData.DeletionMark
	|	AND (&YouDonTNeedToSelectOrganizations
	|			OR CatalogData.Owner IN (&Companies))
	|	AND (&NoCurrencySelectionNeeded
	|			OR CatalogData.CashCurrency = &Currency)
	|	
	|UNION ALL
	|
	|SELECT
	|	""UnallocatedPayments"",
	|	&UnallocatedPaymentsLine,
	|	0 AS OrderField_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashAccountingObjects.Ref AS Value,
	|	CashAccountingObjects.Description AS Presentation,
	|	CASE
	|		WHEN CashAccountingObjects.Ref IN (&BankAccountsCashAccounts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Check
	|FROM
	|	CashAccountingObjects AS CashAccountingObjects
	|
	|ORDER BY
	|	OrderField_,
	|	Presentation";
	
	Query.SetParameter("BankAccountsCashAccounts", BankAccountsCashAccounts);
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("YouDonTNeedToSelectOrganizations", Not Companies.Count());
	Query.SetParameter("Currency", Object.FilterCurrency);
	Query.SetParameter("NoCurrencySelectionNeeded", Not ValueIsFilled(Object.FilterCurrency));
	Query.SetParameter("UnallocatedPaymentsLine", NStr("vi = '<Thanh toán chưa phân bổ>';
														|ru = '<Нераспределенные платежи>';
														|en = '<Open payments>'; fa = '<Open payments>';
														|it = '<Rate non assegnate>';
														|pl = '<Nieprzydzielone płatności>';
														|tr = '<Dağıtılmayan ödemeler>'"));
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Object.FilterBankAccountsCashAccounts.Clear();
	While Selection.Next() Do
		Object.FilterBankAccountsCashAccounts.Add(Selection.Value, Selection.Presentation, Selection.Check);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function SubordinateItem(Tree, Attributes)
	
	SubordinateItem = Undefined;
	SubordinateRows = Tree.GetItems();
	For Each TreeRow In SubordinateRows Do
		RowFits = True;
		For Each Attribute In Attributes Do
			If TreeRow[Attribute.Key] <> Attribute.Value Then
				RowFits = False;
			EndIf;
		EndDo;
		If RowFits Then
			SubordinateItem = TreeRow;
			Break;
		EndIf;
		SubordinateItem = SubordinateItem(TreeRow, Attributes);
		If SubordinateItem <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	Return SubordinateItem;
	
EndFunction

&AtClient
Procedure SetCorrespondenceOfDisplayModesToCommands()
	
	MatchingCommandsAndDisplayModes = New Map();
	MatchingCommandsAndDisplayModes.Insert("ModeApplicationsCalendar", "ApplicationsCalendar");
	MatchingCommandsAndDisplayModes.Insert("ModeCalendarPayments", "CalendarPayments");
	MatchingCommandsAndDisplayModes.Insert("ModeRequestList", "RequestList");
	
EndProcedure

&AtServer
Function CreateCashPaymentRequestsAtServer()

	LineUp = AlignmentOfCurrentList(Items.PaymentsInTheCalendar);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;

	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "BankAccountCashAccount");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentDate");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PayerBeneficiary");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Organization");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "AmountType");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "ReceiptIssue");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Currency");

	FinancialReportingServer.SetFilter(Settings.Filter, "Id", TaggedPaymentEntriesInCalendar);
		
	FinancialReportingServer.SetFilter(Settings.Filter, "ReceiptIssue",
		Enums.CashFlowTypes.WriteOff);
		
	FinancialReportingServer.SetFilter(Settings.Filter, "IsARequest", False);

	GroundsForApplications = FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
	If GroundsForApplications.Count() Then
		Return CashServer.PayChartLines(GroundsForApplications, "PaymentRequest",
					Object.GroupDocumentsWhenCreating);
	Else
		Common.MessageToUser(NStr("vi = 'Trong danh sách không có dòng nào để tạo giấy đề nghị thanh toán.';
									|ru = 'В списке нет строк для формирования заявок к оплате.';
									|en = 'There are no lines for generating payment requests in the list.'; fa = 'There are no lines for generating payment requests in the list.';
									|it = 'There are no lines for generating payment requests in the list.';
									|pl = 'There are no lines for generating payment requests in the list.';
									|tr = 'Listede ödeme talebi oluşturmak için satır yok.'"));
		Return Undefined;
	EndIf;

EndFunction

&AtServer
Function CreateACWATServer()
	
	LineUp = AlignmentOfCurrentList(Items.PaymentsInTheCalendar);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;

	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "BankAccountCashAccount");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentDate");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PayerBeneficiary");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Organization");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "AmountType");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "ReceiptIssue");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Currency");

	FinancialReportingServer.SetFilter(Settings.Filter, "Id", TaggedPaymentEntriesInCalendar);
		
	FinancialReportingServer.SetFilter(Settings.Filter, "ReceiptIssue",
		Enums.CashFlowTypes.WriteOff);
		
	FinancialReportingServer.SetFilter(Settings.Filter, "PaymentMethod", Enums.PaymentForms.BankAccountPayment,
		DataCompositionComparisonType.NotEqual);

	StatusesPayable = New Array;
	StatusesPayable.Add(Enums.StatusesOfPaymentRequests.AmountDue);
	StatusesPayable.Add(Enums.CashTransferOrderStatuses.AmountDue);
	StatusesPayable.Add(Enums.EmployeeApplicationStatuses.AgreedUpon);
	
	FinancialReportingServer.SetFilter(Settings.Filter, "RequestStatus_", StatusesPayable);
	
	ACWFoundations = FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
	If ACWFoundations.Count() Then
		Return CashServer.PayChartLines(ACWFoundations, "CashVoucher",
					Object.GroupDocumentsWhenCreating);
	Else
		MessageText = NStr("vi = 'Trong danh sách không có chứng từ cần thanh toán để tạo các chứng từ Phiếu chi.';
							|ru = 'В списке нет документов к оплате для формирования документов Расходный кассовый ордер.';
							|en = 'There are no documents for payment for ""Outgoing payment — Cash account"" document generation in the list.'; fa = 'There are no documents for payment for ""Outgoing payment — Cash account"" document generation in the list.';
							|it = 'There are no documents for payment for ""Outgoing payment — Cash account"" document generation in the list.';
							|pl = 'There are no documents for payment for ""Outgoing payment — Cash account"" document generation in the list.';
							|tr = 'Listede giden ödeme - kasa hesabı belgeleri oluşturmak için ödeme belgeleri mevcut değil.'");
		Common.MessageToUser(MessageText);
		Return Undefined;
	EndIf;

EndFunction

&AtServerNoContext
Function GraphMeasurements()
	
	Dimensions = New Structure;
	
	For Each Dimension In Metadata.InformationRegisters.ScheduleOfPayments.Dimensions Do
		Dimensions.Insert(Dimension.Name);
	EndDo;
	
	Return Dimensions;
	
EndFunction 

&AtServerNoContext
Function FillInIdSourceAttributesInMarkedLine(GraphMeasurements)
	
	Id = "";
	Record = InformationRegisters.ScheduleOfPayments.CreateRecordManager();
	Record.Fill(Undefined);
	FillPropertyValues(Record, GraphMeasurements);
	Record.Read();

	If Record.Selected() Then
		
		Record.Id = New UUID();
		
		If Not ValueIsFilled(Record.PaymentDateOriginal) Then
			Record.OriginalBankAccountCashAccount = Record.BankAccountCashAccount;
			Record.PaymentDateOriginal = Record.PaymentDate;
			Record.InitialAmount_ = Record.Sum;
		EndIf;
		
		Record.Write();
		Id = Record.Id;
	EndIf;
	
	Return Id;
	
EndFunction

#Region GroupingLevels

&AtServer
Procedure InitializeTheMenuOfGroupingLevels()

	ClearTheMenuOfGroupingLevels();
	FillInTheMenuOfGroupingLevels();
	
	SetTheAvailabilityOfTheGroupingLevelMenu();

EndProcedure

&AtServer
Procedure ClearTheMenuOfGroupingLevels()
	
	Buttons = Items.GroupsLevelsGroup.ChildItems;
	IndexOf = Buttons.Count() - 1;

	While IndexOf >= 0 Do

		Button = Buttons[IndexOf];
		IndexOf = IndexOf - 1;

		If Button = Items.ShowGroupsLevel Then
			Continue;
		EndIf;

		Command = Commands.Find(Button.Name);

		If Command <> Undefined Then
			Commands.Delete(Command);
		EndIf;

		Items.Delete(Button);
	EndDo;

EndProcedure

&AtServer
Procedure FillInTheMenuOfGroupingLevels()
	
	IndexOfTheReportStructure = NewReportStructureIndex();
	
	MenuProperties = PropertiesOfReportDimensionLevelsMenu(IndexOfTheReportStructure);

	For Each Properties In MenuProperties Do

		Command = Commands.Add(Properties.CommandName);
		Command.Title = Properties.RepresentationOfTheGroupingLevel;
		Command.Action = "Attachable_ShowGroupsLevel";
		
		Button = Items.Add(Properties.CommandName, Type("FormButton"), Items.GroupsLevelsGroup);
		Button.Type = FormButtonType.CommandBarButton;
		Button.CommandName = Properties.CommandName;
		Button.Title = Properties.RepresentationOfTheGroupingLevel;
		Button.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
	EndDo;

EndProcedure

&AtServer
Function PropertiesOfReportDimensionLevelsMenu(IndexOfTheReportStructure)
	
	MenuProperties = MenuPropertiesFromReportStructure(IndexOfTheReportStructure);
	GroupingLevel = 0;
	
	For IndexOf = 0 To Object.ReportDimensions.Count() - 1 Do
		
		CurrentGroup = Object.ReportDimensions.Get(IndexOf);
		
		If CurrentGroup.Check Then
			GroupingLevel = GroupingLevel + 1;
			
			Properties = MenuProperties.Add();
			Properties.CommandName = Items.ShowGroupsLevel.Name + GroupingLevel;
			Properties.RepresentationOfTheGroupingLevel = CurrentGroup.Presentation;
		EndIf;
	EndDo;
	
	MenuProperties.Sort("GroupingLevel");
	Return MenuProperties;
	
EndFunction

// Parameters:
//  IndexOfTheReportStructure - See ReportsOptionsInternal.NewReportStructureIndex 
// 
// Returns:
//  ValueTable:
//    * CommandName - String
//    * GroupingLevel - Number
//    * RepresentationOfTheGroupingLevel - String
//
&AtServerNoContext
Function MenuPropertiesFromReportStructure(IndexOfTheReportStructure)

	MenuProperties = IndexOfTheReportStructure.CopyColumns("GroupingOrder, PerformanceGroup"); // ValueTable

	MenuProperties.Columns.Insert(1, "CommandName", New TypeDescription("String"));

	Column = MenuProperties.Columns.Find("GroupingOrder"); // ValueTableColumn
	Column.Name = "GroupingLevel";

	Column = MenuProperties.Columns.Find("PerformanceGroup"); // ValueTableColumn
	Column.Name = "RepresentationOfTheGroupingLevel";

	Return MenuProperties;

EndFunction

&AtServer
Procedure SetTheAvailabilityOfTheGroupingLevelMenu()

	TheMenuIsFull = (Items.GroupsLevelsGroup.ChildItems.Count() > 1);

	Items.ShowGroupsLevel.Visible = Not TheMenuIsFull;

	Items.GroupsLevelsGroup.Visible = TheMenuIsFull;

EndProcedure

&AtClient
Procedure ShowTheSelectedGroupingLevel(GroupingLevel = Undefined)

	CollapseAllLevelsOfTree(Object.PaymentTree.GetItems());

	If GroupingLevel = Undefined Then
		GroupingLevel = 1;
	EndIf;
	
	If GroupingLevel > 1 Then
		ExpandFormDataTree(Object.PaymentTree, GroupingLevel);
	EndIf;

	ReferenceMenu = Items.GroupsLevelsGroup;
	ReferenceButton = Items.ShowGroupsLevel;
	
	MenuOutputAreas = New Map;
	MenuOutputAreas.Insert(ReferenceMenu, ReferenceButton);

	For Each Area In MenuOutputAreas Do

		Buttons = Area.Key.ChildItems;
		For Each Button In Buttons Do
			Button.Check = False;
		EndDo;

		ButtonName = ReferenceButton.Name + GroupingLevel + StrReplace(Area.Value.Name, ReferenceButton.Name, "");
		Button = Buttons.Find(ButtonName);
		If Button <> Undefined Then
			Button.Check = True;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure ExpandFormDataTree(Tree, Level)

	ExpandTreeLevel(Tree.GetItems(), Level, 1);
	
EndProcedure

&AtClient
Procedure ExpandTreeLevel(TreeItems, Level, CurrentLevel)
	
	If CurrentLevel >= Level Then
		Return;
	EndIf;
	
	For Each TreeItem In TreeItems Do
		
		Items.PaymentTree.Expand(TreeItem.GetID());
		
		If TreeItem.GetItems().Count() > 0 Then
			ExpandTreeLevel(TreeItem.GetItems(), Level, CurrentLevel + 1);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseAllLevelsOfTree(TreeItems)
	
	For Each TreeItem In TreeItems Do

		SubordinateTreeElement = TreeItem.GetItems();
		
		If SubordinateTreeElement.Count() > 0 Then
			CollapseAllLevelsOfTree(SubordinateTreeElement);
		EndIf;
		Items.PaymentTree.Collapse(TreeItem.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region FrozenPayments

&AtServer
Function PaymentsToBeFrozenAndRefundedForExecution(Frozen)
	
	LineUp = AlignmentOfCurrentList(Items[CurrentListName]);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;
	
	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "BankAccountCashAccount");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentDate");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PayerBeneficiary");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Organization");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "AmountType");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "ReceiptIssue");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Currency");
	
	FinancialReportingServer.SetFilter(Settings.Filter, "Id",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
	FinancialReportingServer.SetFilter(Settings.Filter, "Frozen", Frozen);
	
	Return FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
EndFunction

&AtServer
Function NumberOfPaymentsToFreezeAndRefundForExecution(Frozen)
	
	ValueTable = PaymentsToBeFrozenAndRefundedForExecution(Frozen);
	
	Return ValueTable.Count();
	
EndFunction

&AtServer
Function FreezeMarkedPaymentsATServer()
	
	PaymentsToBeFrozen = PaymentsToBeFrozenAndRefundedForExecution(False);
	
	JobDescription = NStr("vi = 'Đóng băng các khoản thanh toán.';
							|ru = 'Заморозить платежи.';
							|en = 'Freeze payments.'; fa = 'Freeze payments.';
							|it = 'Freeze payments.';
							|pl = 'Freeze payments.';
							|tr = 'Ödemeleri dondur.'");
	MethodToExecute = "DataProcessors.CashForecast.FreezeRefundPaymentsForExecution";
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Payments_2", PaymentsToBeFrozen);
	ParametersStructure.Insert("Frozen", True);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.RunNotInBackground1 = True;

	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);

EndFunction

&AtClient
Procedure EnteringDateToReturnToExecutionEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TimeConsumingOperation = ReturnToExecutionATServer(Result);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AtEndFreezeReturnToExecution", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure EnteringDepthOfDelayEnd(Result, AdditionalParameters) Export

	If Result = Undefined Or Result <= 0 Then
		Return;
	EndIf;
	
	FreezeOverduePaymentsATServer(Result);

EndProcedure

&AtServer
Function ReturnToExecutionATServer(PaymentDate)
	
	PaymentsToBeRefundedForExecution = PaymentsToBeFrozenAndRefundedForExecution(True);
	
	JobDescription = NStr("vi = 'Đưa các khoản thanh toán trở lại thực hiện.';
							|ru = 'Вернуть на исполнение платежи.';
							|en = 'Return payments to execution.'; fa = 'Return payments to execution.';
							|it = 'Return payments to execution.';
							|pl = 'Return payments to execution.';
							|tr = 'Ödemeleri icraya iade et.'");
	MethodToExecute = "DataProcessors.CashForecast.FreezeRefundPaymentsForExecution";
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Payments_2", PaymentsToBeRefundedForExecution);
	ParametersStructure.Insert("Frozen", False);
	ParametersStructure.Insert("PaymentDate", PaymentDate);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.RunNotInBackground1 = True;

	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);
	
EndFunction

&AtServer
Procedure FreezeOverduePaymentsATServer(DaysOfOverdue)
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	DCS = DataProcessorObject.GetTemplate("PaymentTree");
	SettingsOption = DCS.DefaultSettings;
	
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCS);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(AvailableSettingsSource);
	Composer.LoadSettings(SettingsOption);

	DataCompositionClientServer.CopyElements(Composer.Settings.Filter, Object.LinkerSelection.Settings.Filter);
		
	DataProcessorObject.FillInLayoutParameters(Composer.Settings.DataParameters);
	Composer.Refresh(DataCompositionSettingsRefreshMethod.Full);

	Composer.Settings.Structure.Clear();

	DetailedRecords = Composer.Settings.Structure.Add(Type("DataCompositionGroup"));
	
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "BankAccountCashAccount");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "OriginalPaymentDate");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PayerBeneficiary");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Organization");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "AmountType");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "ReceiptIssue");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Currency");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "DaysOverdue_3");
	
	FinancialReportingServer.SetFilter(Composer.Settings.Filter, "PayerBeneficiary", ,
		DataCompositionComparisonType.Filled);
	FinancialReportingServer.SetFilter(Composer.Settings.Filter, "Frozen", False);
	FinancialReportingServer.SetFilter(Composer.Settings.Filter, "PaymentDate", Object.PlanFromDate,
		DataCompositionComparisonType.Less);
	FinancialReportingServer.SetFilter(Composer.Settings.Filter, "DaysOverdue_3", DaysOfOverdue,
		DataCompositionComparisonType.GreaterOrEqual);

	DCSTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(DCS, Composer);
	Payments_2 = FinancialReportingServer.UploadDCSResultsFromTemplate(DCSTemplate);

	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		For Each Payment_ In Payments_2 Do
		
			Record = InformationRegisters.ScheduleOfPayments.CreateRecordManager();
			Record.Fill(Undefined);
			FillPropertyValues(Record, Payment_);
			Record.PaymentDate = Payment_.OriginalPaymentDate;
			Record.Read();
			
			If Record.Selected() Then
				Record.Frozen = True;
				Record.Write();
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
			
		MessageText = NStr("vi = 'Không thể đóng băng các khoản thanh toán quá hạn với lý do: %1';
							|ru = 'Не удалось заморозить просроченные платежи по причине: %1';
							|en = 'Cannot freeze overdue payments due to: %1'; fa = 'Cannot freeze overdue payments due to: %1';
							|it = 'Cannot freeze overdue payments due to: %1';
							|pl = 'Cannot freeze overdue payments due to: %1';
							|tr = 'Gecikmiş ödemeler şu nedenle dondurulamadı: %1'");
		MessageText = StrTemplate(MessageText, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Common.MessageToUser(MessageText);
	EndTry;
	
	UpdateListsOnServer();
	
	CurFormList = Items[CurrentListName]; // FormTable
	CurFormList.Refresh();
	
EndProcedure

&AtClient
Procedure AtEndFreezeReturnToExecution(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	ClearFlaggedEntries();
	AtEndFreezeAndReturnToExecutionATServer();
	
EndProcedure

&AtServer
Procedure AtEndFreezeAndReturnToExecutionATServer()
	
	UpdateListsOnServer();
	
	CurFormList = Items[CurrentListName]; // FormTable
	CurFormList.Refresh();
	
EndProcedure

#EndRegion

#Region InteractiveActions

&AtServer
Function AmountDueATServer()

	LineUp = AlignmentOfCurrentList(Items[CurrentListName]);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;

	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");

	StatusesPrecedingAmountDue = New Array;
	StatusesPrecedingAmountDue.Add(Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	StatusesPrecedingAmountDue.Add(Enums.StatusesOfPaymentRequests.AgreedUpon);

	FinancialReportingServer.SetFilter(Settings.Filter, "Id",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
	FinancialReportingServer.SetFilter(Settings.Filter, "IsARequest", True);
	FinancialReportingServer.SetFilter(Settings.Filter, "Status", StatusesPrecedingAmountDue);
	
	Requests = FinancialReportingServer.UploadDCSResults(DCS, Settings).UnloadColumn("PaymentObject");
	
	If Requests.Count() = 0 Then
		ErrorText = StrTemplate(NStr("vi = 'Không có chứng từ ""%1"" nào ở trạng thái ""%2"", ""%3"" được chọn.';
									|ru = 'Не отмечено ни одного документа ""%1"" в статусах ""%2"", ""%3"".';
									|en = 'No ""%1"" document in the ""%2"" or ""%3"" statuses is selected.'; fa = 'No ""%1"" document in the ""%2"" or ""%3"" statuses is selected.';
									|it = 'No ""%1"" document in the ""%2"" or ""%3"" statuses is selected.';
									|pl = 'No ""%1"" document in the ""%2"" or ""%3"" statuses is selected.';
									|tr = '""%2"", ""%3"" durumlarında ""%1"" belgesi işaretlenmemiş.'"),
			Metadata.Documents.PaymentRequest.Synonym,
			Metadata.Enums.StatusesOfPaymentRequests.EnumValues.NotAgreedUpon.Synonym,
			Metadata.Enums.StatusesOfPaymentRequests.EnumValues.AgreedUpon.Synonym);
		Common.MessageToUser(ErrorText);
	EndIf;
	
	Return Requests;

EndFunction

&AtServer
Function RejectRequestsATServer()
	
	LineUp = AlignmentOfCurrentList(Items[CurrentListName]);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;

	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "PaymentObject");

	FinancialReportingServer.SetFilter(Settings.Filter, "Id",
		ThisObject[NameOfCurrentListOfTaggedEntries]);
	FinancialReportingServer.SetFilter(Settings.Filter, "IsARequest", True);
	
	Requests = FinancialReportingServer.UploadDCSResults(DCS, Settings).UnloadColumn("PaymentObject");
	
	If Requests.Count() = 0 Then
		ErrorText = StrTemplate(NStr("vi = 'Không có chứng từ ""%1"" nào được chọn.';
									|ru = 'Не отмечено ни одного документа ""%1"".';
									|en = 'No ""%1"" document is selected.'; fa = 'No ""%1"" document is selected.';
									|it = 'No ""%1"" document is selected.';
									|pl = 'No ""%1"" document is selected.';
									|tr = 'Hiçbir ""%1"" belgesi işaretlenmemiş.'"),
			Metadata.Documents.PaymentRequest.Synonym);
		Common.MessageToUser(ErrorText);
	EndIf;
	
	Return Requests;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure ClearFlaggedEntries()
	
	TaggedPaymentEntriesInCalendar.Clear();
	MarkedEntriesOfAmountDueRequest.Clear();
	TotalsQuantity = 0;
	Totals_Amount = 0;
	
EndProcedure

// Gets the schema of the data components, the settings of the data components of the current list
// 
// Parameters:
//  Table - DynamicList
// 
// Returns:
//  Structure:
//   * DCS - DataCompositionSchema
//   * Settings - DataCompositionSettings 
//
&AtServerNoContext
Function AlignmentOfCurrentList(Table)
	
	DCS = Table.GetPerformingDataCompositionScheme(); // DataCompositionSchema
	DCS.DataSets.DynamicListDataSet.Query =
		StrReplace(DCS.DataSets.DynamicListDataSet.Query,
			"SELECT ALLOWED",
			"SELECT DISTINCT ALLOWED"); //@query-part-1 @query-part-2
	Settings = Table.GetPerformingDataCompositionSettings(); // DataCompositionSettings
	Settings.Structure.Clear();

	Return New Structure("DCS, Settings", DCS, Settings);
	
EndFunction

&AtServer
Procedure CheckBoxesOnServer()

	LineUp = AlignmentOfCurrentList(Items[CurrentListName]);
	DCS = LineUp.DCS;
	Settings = LineUp.Settings;
	
	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Id");
	FinancialReportingServer.NewSelectionField(DetailedRecords, "Sum");
	
	Payments_2 = FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
	For Each Payment_ In Payments_2 Do
		
		If Not ValueIsFilled(Payment_.Id) Then
			Continue;
		EndIf;
		ListItem = ThisObject[NameOfCurrentListOfTaggedEntries].FindByValue(Payment_.Id);
		If ListItem = Undefined Then
			ThisObject[NameOfCurrentListOfTaggedEntries].Add(Payment_.Id);
			Totals_Amount = Totals_Amount + Payment_.Sum;
			TotalsQuantity = TotalsQuantity + 1;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Function DescribeResultOfErrorOfLongTermOperationOfOperation(ErrorText)
	
	Result = New Structure;
	Result.Insert("Status", "Error");
	Result.Insert("ResultAddress", "");
	Result.Insert("AdditionalResultAddress", "");
	Result.Insert("BriefErrorDescription", ErrorText);
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("JobID", UUID);
	Result.Insert("ErrorInfo", "");
	
	Messages = New Array();
	Messages.Add(ErrorText);
	Result.Insert("Messages", Messages);
	
	Return Result;
	
EndFunction

// Sets a new selection in the passed selection of the data layout scheme.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  LeftValue - String, DataCompositionField - the layout field for which you want to set the selection.
//  RightValue  - Arbitrary - the value of the selection (optional).
//  Var_ComparisonType  - DataCompositionComparisonType - data layout comparison view (optional).
//  Use  - Boolean - using a new selection element (optional, True by default).
//
&AtServerNoContext
Procedure SetSelectionWithoutSearchingInGroups(FilterDQ, LeftValue, RightValue = Undefined,
	Var_ComparisonType = Undefined, Use = True)
	
	FilterElement = FindSelectionItemWithoutSearchingInGroupsEqualToInList(FilterDQ, LeftValue);
	If FilterElement = Undefined Then
		FilterElement = FinancialReportingServer.NewFilter(FilterDQ, LeftValue, RightValue);
	EndIf;
	FilterElement.Use = Use;
	If Var_ComparisonType <> Undefined Then
		FilterElement.ComparisonType = Var_ComparisonType;
	EndIf;
	If Use Then
		FilterElement.RightValue = RightValue;
	EndIf;
	
EndProcedure

// Returns a reference to the selection element in the passed selection of the data layout schema.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  TagName - String - name of the layout field to use to find the selection element.
//
// Returns:
//   DataCompositionFilterItem - a link to the found selection element of the data layout scheme.
//
&AtServerNoContext
Function FindSelectionItemWithoutSearchingInGroupsEqualToInList(FilterDQ, TagName)
	
	Result = Undefined;
	For Each FilterElement In FilterDQ.Items Do
		If TypeOf(FilterElement) <> Type("DataCompositionFilterItemGroup")
			And FilterElement.LeftValue = New DataCompositionField(TagName) Then
			If FilterElement.ComparisonType = DataCompositionComparisonType.Equal
				Or FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
				Result = FilterElement;
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Returns a reference to the selection element in the passed selection of the data layout schema.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  TagName - String - name of the layout field to use to find the selection element.
//
// Returns:
//   DataCompositionFilterItem - a link to the found selection element of the data layout scheme.
//
&AtServerNoContext
Function FindSelectionElementWithoutSearchingInGroups(FilterDQ, TagName)
	
	Result = Undefined;
	For Each FilterElement In FilterDQ.Items Do
		If TypeOf(FilterElement) <> Type("DataCompositionFilterItemGroup")
			And FilterElement.LeftValue = New DataCompositionField(TagName) Then
			Result = FilterElement;
			Break;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Returns:
//  ValueTable:
//    * SectionOrder - Number
//    * NumberOfPartitions - Number
//    * GroupingOrder - Number
//    * FieldOrder - Number
//    * IDOfTheSettings - DataCompositionID
//    * SectionID - DataCompositionID
//    * GroupingID - DataCompositionID
//    * FieldID - DataCompositionID
//    * Field - DataCompositionField
//    * FieldType - Type
//    * UsedInGroupingFields - Boolean
//    * GroupType - DataCompositionGroupType
//    * GroupName - String
//    * PerformanceGroup - String
//    * FieldPresentation - String
//    * Text - String
//    * Period - Boolean
//    * Dimension - Boolean
//    * Resource - Boolean
//    * IsFormula - Boolean
//    * ValueType - Type
//    * TheFieldIsSorted - Boolean
//    * SortDirection - DataCompositionSortDirection
//    * GroupBySelectedField - Boolean
//    * InsertFieldLeft - Boolean
//    * InsertFieldRight - Boolean
//    * InsertGroupAbove - Boolean
//    * InsertGroupBelow - Boolean
//    * MoveFieldLeft - Boolean
//    * MoveFieldRight - Boolean
//    * MoveFieldUp - Boolean
//    * MoveFieldDown - Boolean
//    * HideField - Boolean
//    * RenameField - Boolean
//    * FormatNegativeValues - Boolean
//    * FormatPositiveValues - Boolean
//    * ApplyAppearanceMore - Boolean
//    * ContainsTheParentGroup - Boolean
//    * ContainsChildGroupings - Boolean
//    * IndexID - UUID
// 
&AtServerNoContext
Function NewReportStructureIndex()
	
	NumberDetails = New TypeDescription("Number");
	RowDescription = New TypeDescription("String");
	FlagDetails = New TypeDescription("Boolean");
	FieldDetails = New TypeDescription("DataCompositionField");
	TypeDescription = New TypeDescription("TypeDescription");
	TypeDetails = New TypeDescription("Type");
	IDDetails = New TypeDescription("UUID");
	DescriptionOfTheGroupingType = New TypeDescription("DataCompositionGroupType");
	
	IndexOf = New ValueTable;
	IndexOf.Columns.Add("SectionOrder", NumberDetails);
	IndexOf.Columns.Add("NumberOfPartitions", NumberDetails);
	IndexOf.Columns.Add("GroupingOrder", NumberDetails);
	IndexOf.Columns.Add("FieldOrder", NumberDetails);
	
	IndexOf.Columns.Add("IDOfTheSettings");
	IndexOf.Columns.Add("SectionID");
	IndexOf.Columns.Add("GroupingID");
	IndexOf.Columns.Add("FieldID");
	
	IndexOf.Columns.Add("Field", FieldDetails);
	IndexOf.Columns.Add("FieldType", TypeDetails);
	
	IndexOf.Columns.Add("UsedInGroupingFields", FlagDetails);
	IndexOf.Columns.Add("GroupType", DescriptionOfTheGroupingType);
	
	IndexOf.Columns.Add("GroupName", RowDescription);
	IndexOf.Columns.Add("PerformanceGroup", RowDescription);
	IndexOf.Columns.Add("FieldPresentation", RowDescription);
	IndexOf.Columns.Add("Text", RowDescription);
	
	IndexOf.Columns.Add("Period", FlagDetails);
	IndexOf.Columns.Add("Dimension", FlagDetails);
	IndexOf.Columns.Add("Resource", FlagDetails);
	IndexOf.Columns.Add("IsFormula", FlagDetails);
	
	IndexOf.Columns.Add("ValueType", TypeDescription);
	IndexOf.Columns.Add("TheFieldIsSorted", FlagDetails);
	IndexOf.Columns.Add("SortDirection");
	
	IndexOf.Columns.Add("GroupBySelectedField", FlagDetails);
	
	IndexOf.Columns.Add("InsertFieldLeft", FlagDetails);
	IndexOf.Columns.Add("InsertFieldRight", FlagDetails);
	IndexOf.Columns.Add("InsertGroupAbove", FlagDetails);
	IndexOf.Columns.Add("InsertGroupBelow", FlagDetails);
	
	IndexOf.Columns.Add("MoveFieldLeft", FlagDetails);
	IndexOf.Columns.Add("MoveFieldRight", FlagDetails);
	IndexOf.Columns.Add("MoveFieldUp", FlagDetails);
	IndexOf.Columns.Add("MoveFieldDown", FlagDetails);
	
	IndexOf.Columns.Add("HideField", FlagDetails);
	IndexOf.Columns.Add("RenameField", FlagDetails);
	
	IndexOf.Columns.Add("FormatNegativeValues", FlagDetails);
	IndexOf.Columns.Add("FormatPositiveValues", FlagDetails);
	IndexOf.Columns.Add("ApplyAppearanceMore", FlagDetails);
	
	IndexOf.Columns.Add("ContainsTheParentGroup", FlagDetails);
	IndexOf.Columns.Add("ContainsChildGroupings", FlagDetails);
	
	IndexOf.Columns.Add("IndexID", IDDetails);
	
	Return IndexOf;
	
EndFunction

&AtServerNoContext
Function CompactModeScale()
	
	Return 80;
	
EndFunction

&AtClientAtServerNoContext
Function LongTermPeriodByPaymentDate(PaymentDate, LongTermPeriods)

	PerirodLine = Undefined;

	For Each Page1 In LongTermPeriods Do
		
		If Page1.StartDate <= PaymentDate And Page1.EndDate >= PaymentDate Then
			PerirodLine = Page1;
			Break;
		EndIf;
	EndDo;

	Return PerirodLine;

EndFunction

#EndRegion

#EndRegion

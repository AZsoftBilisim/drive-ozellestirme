
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	// Getting a FO
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	// Installation of selections.
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization",        Organization);
		QuickFilterStructure.Property("Warehouse",              Warehouse);
		QuickFilterStructure.Property("InvoiceStatus", InvoiceStatus);
		QuickFilterStructure.Property("NoteState",    NoteState);
		QuickFilterStructure.Property("Ref",			   FilterReferences);
	EndIf;
	
	If Not UseSeveralWarehouses
		And Not ValueIsFilled(Warehouse) Then
		Warehouse = Catalogs.Warehouses.DefaultWarehouse();
	EndIf;
	
	If Not Parameters.Property("FormAssignmentKey")
		Or IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DefaultFormAssignmentKey();
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"Warehouse",
		Warehouse,
		QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"InvoiceStatus",
		?(ValueIsFilled(InvoiceStatus), Number(InvoiceStatus), InvoiceStatus),
		QuickFilterStructure,,,
		ValueIsFilled(InvoiceStatus));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"NoteState",
		?(ValueIsFilled(NoteState), Number(NoteState), NoteState),
		QuickFilterStructure,,,
		ValueIsFilled(NoteState));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"Organization",
		Organization,
		QuickFilterStructure);
		
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"Ref",
		FilterReferences,
		QuickFilterStructure);
	
	Items.Warehouse.Visible = UseSeveralWarehouses;
	
	Items.ListReferencesForRegistrationNoteState.Visible = UseWarehouseManagemantSystemForGoodsIssue;
	Items.ListReferencesForRegistrationInvoiceStatus.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	Items.NoteState.Visible = UseWarehouseManagemantSystemForGoodsIssue;
	Items.InvoiceStatus.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationOrganization",
		"Visible",
		GetFunctionalOption("UseMultipleCompanies"));
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationWarehouse",
		"Visible",
		UseSeveralWarehouses);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationCurrency",
		"Visible",
		GetFunctionalOption("UseMultipleCurrencies"));
	
	ListReferencesForRegistration.Parameters.SetParameterValue("CurrentDate", BegOfDay(CurrentSessionDate()));
	
	HaveRightToReadLeftovers = AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	
	ThereIsRightToAddReceiptsFromCustodian = AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian);
	
	Items.ListReferencesForRegistration.Visible = HaveRightToReadLeftovers;
	
	Items.ListReferencesForRegistrationRegisterByOrders.Visible = ThereIsRightToAddReceiptsFromCustodian
																			Or AccessRight("Insert", Metadata.Documents.ReturnOfGoodsFromCustomer);
	Items.ListReferencesForRegistrationRegisterByReceiving.Visible = ThereIsRightToAddReceiptsFromCustodian
																			Or AccessRight("Insert", Metadata.Documents.ReturnOfGoodsFromCustomer);
	Items.ListReferencesForRegistrationExecutionState.Visible = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
	FillSelectionListsByShipmentStates();
	
	Items.ListReferencesForRegistrationCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ReturnOfGoodsFromCustomer"
		Or EventName = "Write_ReceiptOfGoodsFromCustodian"
		Or EventName = "Write_RequestForReturnOfGoodsFromCustomer"
		Or EventName = "Write_GoodsReceiptNote"
		Or EventName = "Accept_FormOfCreatedDocuments" Then
		
		Items.ListReferencesForRegistration.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Warehouse", Warehouse);
		Settings.Delete("Warehouse");
		QuickFilterStructure.Property("InvoiceStatus", InvoiceStatus);
		Settings.Delete("InvoiceStatus");
		QuickFilterStructure.Property("NoteState", NoteState);
		Settings.Delete("NoteState");
		QuickFilterStructure.Property("Organization", Organization);
		Settings.Delete("Organization");
	Else
		Warehouse              = Settings.Get("Warehouse");
		InvoiceStatus = Settings.Get("InvoiceStatus");
		NoteState    = Settings.Get("NoteState");
		Organization        = Settings.Get("Organization");
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"InvoiceStatus",
		?(ValueIsFilled(InvoiceStatus), Number(InvoiceStatus), InvoiceStatus),
		QuickFilterStructure, 
		Settings,
		ValueIsFilled(InvoiceStatus),
		,
		True);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"NoteState",
		?(ValueIsFilled(NoteState), Number(NoteState), NoteState),
		QuickFilterStructure,
		Settings,
		ValueIsFilled(NoteState),
		,
		True);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"Organization",
		Organization,
		QuickFilterStructure,
		Settings,
		ValueIsFilled(Organization));
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"Warehouse",
		Warehouse,
		QuickFilterStructure,
		Settings,
		ValueIsFilled(Warehouse));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForRegistration,
		"Warehouse",
		Warehouse,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Warehouse));
	
EndProcedure

&AtClient
Procedure ListReferencesForRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure InvoiceStatusOnChange(Item)
	
	State = ?(ValueIsFilled(InvoiceStatus), Number(InvoiceStatus), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"InvoiceStatus",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(InvoiceStatus),
		DataCompositionSettingsItemViewMode.Inaccessible);
		
EndProcedure

&AtClient
Procedure NoteStateOnChange(Item)
	
	State = ?(ValueIsFilled(NoteState), Number(NoteState), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"NoteState",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(NoteState));
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForRegistration,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure HyperlinkSalesLogURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "ReturnOfGoodsFromCustomer");
	FormParameters.Insert("FormUniqueID", False);

	NameOfFormToOpen_ = "DataProcessor.LogOfSalesDocuments.Form.DocumentsList";
	
	OpenForm(NameOfFormToOpen_, FormParameters,, FormParameters.FormUniqueID);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueByOrder(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfSalesDocuments.ToRegisterReturnInvoices.Command.IssueByOrder");
	
	CurrentData = Items.ListReferencesForRegistration.CurrentData;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(CurrentData, LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ByNotes = False;
	RegisterInvoices(False);
	
EndProcedure

&AtClient
Procedure RegisterByReceiving(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfSalesDocuments.ToRegisterReturnInvoices.Command.RegisterByReceiving");
		
	CurrentData = Items.ListReferencesForRegistration.CurrentData;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(CurrentData,LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ByNotes = True;
	RegisterInvoices(True);
	
EndProcedure

&AtClient
Procedure ExecutionState(Command)
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	DocumentsList = New ValueList;
	ArrayOfDocumentTypes_ = New Array;
	For Each SelectedRow In SelectedRows Do
		
		SelectedDocument_ = Items.ListReferencesForRegistration.RowData(SelectedRow).Ref;
		SelectedDocumentType_ = TypeOf(SelectedDocument_);
		
		If	SelectedDocumentType_ = Type("DocumentRef.ReturnOfGoodsFromCustomer")
				Or SelectedDocumentType_ = Type("DocumentRef.SaleAdjustment")
				Or SelectedDocumentType_ = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			ShowMessageBox( , StrTemplate(NStr("vi = 'Không thể thực hiện lệnh cho chứng từ %1.';
												|ru = 'Команда не может быть выполнена для документов %1.';
												|en = 'Cannot execute the command for %1 documents.'; fa = 'Cannot execute the command for %1 documents.';
												|it = 'Команда не может быть выполнена для документов %1.';
												|pl = 'Cannot execute the command for %1 documents.';
												|tr = '%1 belgeleri için komut gerçekleştirilemez.'"), SelectedDocumentType_));
			Return;
		EndIf;
		
		If ArrayOfDocumentTypes_.Find(SelectedDocumentType_) = Undefined Then
			ArrayOfDocumentTypes_.Add(SelectedDocumentType_);
			If ArrayOfDocumentTypes_.Count() > 1 Then
				ShowMessageBox( , NStr("vi = 'Lệnh không thể được thực thi cho các chứng từ thuộc các loại khác nhau.';
										|ru = 'Команда не может быть выполнена для документов разного вида.';
										|en = 'Command cannot be executed for documents of different kinds.'; fa = 'Command cannot be executed for documents of different kinds.';
										|it = 'Il comando non può essere eseguito per i documenti di tipo diverso.';
										|pl = 'Polecenie nie może być wykonane dla dokumentów różnego rodzaju.';
										|tr = 'Komut farklı belge türleri için yürütülemez.'"));
				Return;
			EndIf;
		EndIf;
		
		If DocumentsList.FindByValue(SelectedDocument_) = Undefined Then
			DocumentsList.Add(SelectedDocument_);
		EndIf;
		
	EndDo;
	
	If DocumentsList.Count() = 0 Then
		Return;
	EndIf;
	
	OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", 
		New Structure("IncomingDocuments", DocumentsList), 
		ThisForm,
		False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Conditional design of the dynamic list "List of assignments"
	ListOfConditionalAppearance = ListReferencesForRegistration.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReferencesForRegistration.Date", Items.ListReferencesForRegistrationDocumentDate.Name);
	
EndProcedure

&AtServer
Function FillSelectionListsByShipmentStates()
	
	ChoiceList = Items.InvoiceStatus.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("0", NStr("vi = 'Mọi thứ đều được đóng khung';
							|ru = 'Все оформлено';
							|en = 'Fully issued/received'; fa = 'Fully issued/received';
							|it = 'Formalizzato tutto';
							|pl = 'Wszystko jest sporządzone';
							|tr = 'Tümü düzenlenmiş'"), False, PictureLib.InvoiceIsRegistered);
	ChoiceList.Add("1", NStr("vi = 'Tạo hóa đơn bán hàng';
							|ru = 'Создать накладную';
							|en = 'Create invoice'; fa = 'ایجاد فاکتور';
							|it = 'Creare una bolla';
							|pl = 'Utwórz list przewozowy';
							|tr = 'İrsaliye oluştur'"), False, PictureLib.CreateInvoice);
	ChoiceList.Add("2", NStr("vi = 'Gia hạn hóa đơn';
							|ru = 'Дооформить накладную';
							|en = 'Pending issue/receipt'; fa = 'Pending issue/receipt';
							|it = 'Completare la bolla';
							|pl = 'Sporządź do końca list przewozowy';
							|tr = 'İrsaliyeyi tamamla'"), False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
	
	ChoiceList = Items.NoteState.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("0", NStr("vi = 'Hóa đơn khớp';
							|ru = 'Соответствуют накладным';
							|en = 'Notes correspond to the invoices'; fa = 'Notes correspond to the invoices';
							|it = 'Corrispondono alle bolle';
							|pl = 'Odpowiadają listom przewozowym';
							|tr = 'İrsaliyelere uygun'"), False, PictureLib.InvoiceIsRegistered);
	ChoiceList.Add("1", NStr("vi = 'Không đóng khung';
							|ru = 'Не оформлены';
							|en = 'Pending creation'; fa = 'در انتظار ایجاد';
							|it = 'Non sono formalizzati';
							|pl = 'Nie są sporządzone';
							|tr = 'Düzenlenmemiş'"), False, PictureLib.CreateInvoice);
	ChoiceList.Add("3", NStr("vi = 'Không khớp hóa đơn';
							|ru = 'Не соответствуют накладным';
							|en = 'Received vs invoiced mismatch'; fa = 'Received vs invoiced mismatch';
							|it = 'Non corrispondono alle bolle';
							|pl = 'Nie odpowiadają listom przewozowym';
							|tr = 'İrsaliyelere uygun değil.'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
	ChoiceList.Add("4", NStr("vi = 'Không có sơ đồ đặt hàng được sử dụng';
							|ru = 'Не используется ордерная схема';
							|en = 'Warehouse management is not used'; fa = 'Warehouse management is not used';
							|it = 'Lo schema dei mandati non viene utilizzato';
							|pl = 'Nie jest używany schemat zleceń';
							|tr = 'Ambar yönetimi şeması kullanılmamaktadır'"), False, PictureLib.AnEmptyPicture);
	
EndFunction

#Region CreatingNewDocuments

&AtClient
Procedure RegisterInvoices(ByNotes)
	
	IssueInvoicesToClient(ByNotes);
	
EndProcedure

&AtClient
Procedure IssueInvoicesToClient(ByNotes)
	
	ClearMessages();
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	ListOfOrders_.Clear();
	
	For Each String In SelectedRows Do
		FoundRow = Items.ListReferencesForRegistration.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters
	ParametersOfCreatedDocuments = IssueInvoiceOnServer(ByNotes);
	If ParametersOfCreatedDocuments.Property("IssueNumberOfInvoices") And ParametersOfCreatedDocuments.IssueNumberOfInvoices Then
		TimeConsumingOperation = ParametersOfCreatedDocuments.TimeConsumingOperation;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackDescription = New CallbackDescription("IssueInvoicesToClientCompletion", ThisObject, ParametersOfCreatedDocuments);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	Else
		IssueInvoicesToClientCompletion(Undefined, ParametersOfCreatedDocuments);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueInvoicesToClientCompletion(Result, AddlParameters) Export
	
	If Not Result = Undefined Then
		
			If Result.Status = "Error" Then
				
				ParametersOfCreatedDocuments = AddlParameters;
				
				CommonClientServer.AddUserError(ParametersOfCreatedDocuments.ErrorList, "Object.ListReferencesForRegistration",
					Result.BriefErrorDescription);
				
			Else
				
				ParametersOfCreatedDocuments = GetFromTempStorage(Result.ResultAddress);
				
			EndIf;
			
	Else
			
		ParametersOfCreatedDocuments = AddlParameters;
			
	EndIf;
	
	If Not ParametersOfCreatedDocuments.ErrorList = Undefined Then

		If TypeOf(ParametersOfCreatedDocuments.ErrorList) = Type("Array") Then
			
			UserErrors = Undefined;
		
			For Each Error In ParametersOfCreatedDocuments.ErrorList Do
				CommonClientServer.AddUserError(UserErrors, Error.Field, Error.Text, "");
			EndDo;
		
			CommonClientServer.ReportErrorsToUser(UserErrors);
			
		Else
			CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
		EndIf;
		
	EndIf;
	
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
	
	Items.ListReferencesForRegistration.Refresh();
	
EndProcedure

&AtServer
Function SettingsOfInvoiceReissueForm(InvoiceName)
	
	FormSettings= InvoicesServer.SettingsOfInvoiceReissueForm();
	FormSettings.Title = NStr("vi = 'Cấp lại chứng từ cho các đơn hàng đã chọn';
								|ru = 'Переоформление документов по выбранным распоряжениям';
								|en = 'Reregister documents for the selected references'; fa = 'Reregister documents for the selected references';
								|it = 'La formalizzazione sostitutiva dei documenti per disposizioni selezionate';
								|pl = 'Ponowna rejestracja dokumentów wg wybranych zamówień';
								|tr = 'Seçilen emirler için belgelerin yeniden düzenlenmesi'");
	FormSettings.NameOfTheInvoiceForm = "Document." + InvoiceName + ".Form.DocumentForm";
	FormSettings.ReceivingDocument = True;
	FormSettings.ShippingSlip = False;
	
	Return FormSettings;
	
EndFunction

&AtClient
Function LogParameters(Var_PurposeUseKey)
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("WorkplaceName","LogOfSalesDocuments");
	LogParameters.Insert("FormAssignmentKey",Var_PurposeUseKey);
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ bán hàng';
												|ru = 'Документы продажи';
												|en = 'Sales documents'; fa = 'اسناد فروش';
												|it = 'Documenti di vendita';
												|pl = 'Dokumenty sprzedaży';
												|tr = 'Satış belgeleri'"));
	
	Return LogParameters;
	
EndFunction

&AtServer
Function IssueInvoiceOnServer(ByNotes)
	
	Var ErrorList;
	
	FormParameters = New Structure();
	FormParameters.Insert("IssueNumberOfInvoices", False);
	FormParameters.Insert("AddressDocumentsByInvoiceType", Undefined);
	FormParameters.Insert("TimeConsumingOperation", Undefined);
	FormParameters.Insert("ErrorList", ErrorList);
	FormParameters.Insert("CurPackageNumber");
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = SplitOrdersByFullInvoiceNames(ByNotes, ErrorList);
	
	If DocumentsByTypesOfInvoices.Count() > 0 Then
		If ByNotes Then
			
			// If one document is selected and there is at least one invoice, the invoice re-filling form opens.
			// If there are no invoices and the documents can be grouped into one invoice, a new invoice form opens.
			// If there are no invoices and the documents cannot be grouped, the form of the list of created invoices opens.
			
			ThereIsInvoice = ThereIsInvoice(DocumentsByTypesOfInvoices);
			ThereSWarrant     = ThereSWarrant(DocumentsByTypesOfInvoices);
			ThereIsOrder     = ThereIsOrder(DocumentsByTypesOfInvoices);
			
			TotalTables = DocumentsByTypesOfInvoices.Count();
			If TotalTables > 1 Then
				
				If ThereIsInvoice Then
					// Batch with the exclusion of invoices and a message about the excluded documents
					// of the Order-invoices are excluded, because they must be processed individually - it is impossible to enter a new invoice 
					// by order-invoice
					
					ExcludeOrdersWithInvoices(DocumentsByTypesOfInvoices, ErrorList);
					TablesLeft = DocumentsByTypesOfInvoices.Count();
					If TablesLeft > 0 Then
						FormParameters.IssueNumberOfInvoices = True;
						StorageAddress = PutToTempStorage(DocumentsByTypesOfInvoices);
						FormParameters.AddressDocumentsByInvoiceType = StorageAddress;
						
						TimeConsumingOperation = CreateInvoicesAccordingToTables(FormParameters);
						FormParameters.TimeConsumingOperation = TimeConsumingOperation;
						
					EndIf;
					
					If TablesLeft = 0 Then
						ErrorText = NStr("vi = 'Chưa thực hiện giao dịch.';
										|ru = 'Операция не выполнена.';
										|en = 'Operation failed.'; fa = 'Operation failed.';
										|it = 'Operazione non è eseguita.';
										|pl = 'Operacja nie powiodła się.';
										|tr = 'İşlem tamamlanmadı.'");
						CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
					ElsIf TotalTables <> TablesLeft Then
						ErrorText = NStr("vi = 'Các hoạt động hoàn thành với lỗi.';
										|ru = 'Операция выполнена с ошибками.';
										|en = 'Operation is completed with errors.'; fa = 'Operation is completed with errors.';
										|it = 'Operazione eseguita con errori.';
										|pl = 'Operacja zakończona z błędami.';
										|tr = 'İşlem hatalarla tamamlandı'");
						CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
					EndIf;
					
				Else
					// Batch if there are no invoices
					FormParameters.IssueNumberOfInvoices = True;
					StorageAddress = PutToTempStorage(DocumentsByTypesOfInvoices);
					FormParameters.AddressDocumentsByInvoiceType = StorageAddress;
					
					TimeConsumingOperation = CreateInvoicesAccordingToTables(FormParameters);
					FormParameters.TimeConsumingOperation = TimeConsumingOperation;
					
				EndIf;
				
			ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
				// Individually
				
				// Checking for invoices
				// If the current order is an order and there are invoices for it, open the re-filling form
				If ThereIsInvoice And ThereIsOrder Then
					// Opening the re-filling form
					FormParameters = FillItOutUsingFillInForm(DocumentsByTypesOfInvoices, ByNotes, ErrorList);
				Else
					// When trying to fill out an invoice for a missing order, we will issue an error
					If ThereIsInvoice And Not ThereSWarrant Then
						ErrorText = NStr("vi = 'Xử lý đăng ký là không có sẵn, vì không có một đơn đặt hàng đã được tạo ra.';
										|ru = 'Недоступно оформление по приемке, так как не создано ни одного ордера.';
										|en = 'Cannot register receipt as no note is created.'; fa = 'Cannot register receipt as no note is created.';
										|it = 'La formalizzazione per l''accettazione non è disponibile, in quanto non è stato creato alcun mandato.';
										|pl = 'Rejestracja do akceptacji nie jest dostępna, ponieważ nie utworzono żadnych zamówień.';
										|tr = 'Herhangi bir emir oluşturulmadığı için kabulde mevcut değildir.'");
						CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
					Else
						// If this order is an invoice, or an order without an invoice - opening the invoice form, existing or new
						FormParameters = IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices, ByNotes, ErrorList);
					EndIf;
				EndIf;
				
			EndIf;
			
		Else
			
			// When placing orders, a new invoice is always created
			
			// The form of the created invoice opens, if the key fields of the selected lines match, and the functional option allows
			// Otherwise, a form opens with a list of created invoices
			
			If DocumentsByTypesOfInvoices.Count() > 1 Then
				// Batch
				FormParameters.IssueNumberOfInvoices = True;
				StorageAddress = PutToTempStorage(DocumentsByTypesOfInvoices);
				FormParameters.AddressDocumentsByInvoiceType = StorageAddress;
				
				TimeConsumingOperation = CreateInvoicesAccordingToTables(FormParameters);
				FormParameters.TimeConsumingOperation = TimeConsumingOperation;
				
			ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
				// Individually
				FormParameters = IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices, ByNotes, ErrorList);
			EndIf;
			
		EndIf;
	ElsIf ListOfOrders_.Count() > 1
		Or (DocumentsByTypesOfInvoices.Count() = 0 And Not ValueIsFilled(ErrorList)) Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Không có chứng từ nào được chọn có thể được thực thi %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		If ByNotes Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo nhập kho';
																								|ru = 'по приемке';
																								|en = 'by receipt'; fa = 'by receipt';
																								|it = 'accettazione';
																								|pl = 'wg odbioru';
																								|tr = 'tedariğe göre'"));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																								|ru = 'по заказам';
																								|en = 'by orders'; fa = 'by orders';
																								|it = 'per ordini';
																								|pl = 'wg zamówień';
																								|tr = 'siparişlere ilişkin'"));
		EndIf;
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

&AtClientAtServerNoContext
Function ThereIsInvoice(DocumentsByTypesOfInvoices)
	
	For Each Table In DocumentsByTypesOfInvoices Do
		For Each String In Table Do
			// Status "1" - the invoice has not been created. The remaining states imply the presence of an invoice, or an invoice without an order
			If String.InvoiceStatus <> 1 Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Function ThereSWarrant(DocumentsByTypesOfInvoices)
	
	For Each Table In DocumentsByTypesOfInvoices Do
		For Each String In Table Do
			// Status "1" - the order has not been created. The remaining states imply the presence of an order, or that an order is not required (state 4)
			If String.NoteState <> 1 Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function ThereIsOrder(DocumentsByTypesOfInvoices)
	
	For Each Table In DocumentsByTypesOfInvoices Do
		For Each String In Table Do
			If TypeOf(String.Ref)= Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

// Parameters:
// 	ByNotes - Boolean
// 	ErrorList - ValueList
// Returns:
//	Array of See SplitTableTemplate_
&AtServer
Function SplitOrdersByFullInvoiceNames(ByNotes, ErrorList)
	
	SplitTableTemplate = SplitTableTemplate_();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort("Ref, Warehouse, BusinessOperation, InvoiceStatus, NoteState");
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	BatchMode = ListOfOrders_.Count() > 1;
	
	For Each String In ListOfOrders_ Do
	
		ErrorText = "";
		AbortStringProcessing = False;
		
		If ByNotes Then
			
			If String.NoteState = 0 Then
				
				ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể nạp lại hóa đơn chấp nhận, vì đơn hàng tương ứng với hóa đơn.';
								|ru = 'Для распоряжения %1 невозможно перезаполнить накладную по приемке, т.к. ордера соответствуют накладным.';
								|en = 'Cannot refill a receipt invoice for the %1 reference as the notes match the invoices.'; fa = 'Cannot refill a receipt invoice for the %1 reference as the notes match the invoices.';
								|it = 'Per la disposizione %1 non è possibile ricompilare la bolla dell''accettazione, in quanto i mandati corrispondono alle bolle.';
								|pl = 'Dla zamówienia %1 niemożliwe jest uzupełnienie faktury do akceptacji, ponieważ zlecenia odpowiadają fakturom.';
								|tr = '%1 emri için, emirler irsaliyelere karşılık geldiğinden irsaliyenin üzerine yazılması mümkün değildir.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				
				AbortStringProcessing = True;
				
			ElsIf String.NoteState = 4 Then
				
				ErrorText = NStr("vi = 'Đối với lệnh %1, không thể tạo phiếu nhập kho, bởi vì kho bãi %2 không sử dụng sơ đồ hai pha.';
								|ru = 'Для распоряжения %1 невозможно оформить накладную по приемке, т.к. склад %2 не использует ордерную схему.';
								|en = 'Cannot register a receipt invoice for the %1 reference as the %2 warehouse does not use warehouse management.'; fa = 'Cannot register a receipt invoice for the %1 reference as the %2 warehouse does not use warehouse management.';
								|it = 'Для распоряжения %1 невозможно оформить накладную по приемке, т.к. склад %2 не использует ордерную схему.';
								|pl = 'Cannot register a receipt invoice for the %1 reference as the %2 warehouse does not use warehouse management.';
								|tr = '%2 ambarı emir planını kullanmadığı için %1 emri için bir irsaliye düzenlemek mümkün değildir.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref, String.Warehouse);
				
				AbortStringProcessing = True;
				
			EndIf;
			
		Else // execution by orders
			
			If TypeOf(String.Ref)= Type("DocumentRef.ReturnOfGoodsFromCustomer")
					Or TypeOf(String.Ref)= Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
				
				ErrorText = NStr("vi = 'Lệnh %1 là hóa đơn. Đối với hóa đơn, đặt hàng là không có sẵn.';
								|ru = 'Распоряжение %1 явлется накладной. Для накладных оформление по заказам не доступно.';
								|en = 'Reference %1 is an invoice. Registration against orders is not available for invoices.'; fa = 'Reference %1 is an invoice. Registration against orders is not available for invoices.';
								|it = 'La disposizione %1 è una bolla. Per le bolle non è disponibile la formalizzazione per ordini.';
								|pl = 'Zamówienie %1 jest fakturą. Dla faktur rejestracja wg zamówień nie jest dostępna.';
								|tr = '%1 emri bir irsaliye yerine geçer. İrsaliye için sipariş düzenlemesi gerekmez.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
				
			ElsIf String.InvoiceStatus = 0 Then
				
				ErrorText = NStr("vi = 'Một hóa đơn đã được tạo cho đơn hàng %1';
								|ru = 'Для распоряжения %1 уже создана накладная';
								|en = 'An invoice has already been created for the %1 reference'; fa = 'An invoice has already been created for the %1 reference';
								|it = 'Per la disposizione %1 è già creata una bolla';
								|pl = 'Dla zamówienia %1 została już utworzona faktura';
								|tr = '%1 emri için bir irsaliye zaten oluşturuldu.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
				
			EndIf;
			
		EndIf;
		
		If Not IsBlankString(ErrorText) Then
			CommonClientServer.AddUserError(ErrorList,
				"Object.ListReferencesForRegistration",
				ErrorText,
				Undefined);
		EndIf;
		
		If AbortStringProcessing Then
			Continue;
		EndIf;
		
		// In this workplace, there are no invoices that can be issued for several orders,
		// so a separate table is formed for each selected row
		
		SplitTable = SplitTableTemplate.Copy();
		ArrayOfTables.Add(SplitTable);
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

&AtServer
Procedure ExcludeOrdersWithInvoices(DocumentsByTypesOfInvoices, ErrorList)
	
	InitialQuantity = DocumentsByTypesOfInvoices.Count();
	For Iteration = 1 To InitialQuantity Do
		IndexOf = InitialQuantity - Iteration;
		Table = DocumentsByTypesOfInvoices[IndexOf];
		
		Exclude = False;
		For Each TableRow In Table Do
			
			If TableRow.InvoiceStatus <> 1 Then
				Exclude = True;
				Break;
			EndIf;
			
		EndDo;
		
		If Exclude Then
			
			For Each String In Table Do
				ErrorText = NStr("vi = 'Đối với đơn hàng %1, giao dịch chưa được hoàn thành, vì đã có hóa đơn cho các đơn hàng đã chọn.';
								|ru = 'Для распоряжения %1 действие не выполнено, так как по выбранным распоряжениям уже имеются накладные.';
								|en = 'Action is not performed for the %1 reference as invoices for the selected references already exist.'; fa = 'Action is not performed for the %1 reference as invoices for the selected references already exist.';
								|it = 'Per la disposizione %1 l''azione non è eseguita, in quanto per le disposizioni selezionate vi sono già le bolle.';
								|pl = 'Dla zamówienia %1 działanie nie powiodło się, ponieważ w wybranych zamówieniach już są faktury.';
								|tr = '%1 emri için eylem gerçekleştirilmez çünkü seçilen emirler için zaten irsaliyeler vardır.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
			EndDo;
			
			DocumentsByTypesOfInvoices.Delete(IndexOf);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function CreateInvoicesAccordingToTables(ParametersStructure)
	
	JobDescription = NStr("vi = 'Lập chứng từ hoàn trả';
							|ru = 'Оформление документов возврата';
							|en = 'Register return documents'; fa = 'Register return documents';
							|it = 'La formalizzazione dei documenti di restituzione';
							|pl = 'Rejestracja dokumentów na zwrot';
							|tr = 'İade belgelerinin oluşturulması'");
	MethodToExecute = "SalesServer.RegisterInvoices";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	ParameterStructureIsNew = Common.CopyRecursive(ParametersStructure);
	ParameterStructureIsNew.Insert("RunNotInBackground1", False);
	
	StorageAddress = ParametersStructure.AddressDocumentsByInvoiceType;
	DocumentsByTypesOfInvoices = GetFromTempStorage(StorageAddress);
	DeleteFromTempStorage(StorageAddress);
	
	If DocumentsByTypesOfInvoices.Count() < 10 Then
		ParameterStructureIsNew.RunNotInBackground1 = True;
	EndIf;
	ParameterStructureIsNew.Insert("DocumentsByTypesOfInvoices", DocumentsByTypesOfInvoices);
	
	GenerationParameters = DocumentGenerationParameters();
	If ValueIsFilled(DocumentsByTypesOfInvoices) Then
		DocumentsTable = DocumentsByTypesOfInvoices[0];
		SelectedRow  = DocumentsTable[0];
		InvoiceMetadata = MetadataOfTransactionInvoice(SelectedRow);
		GenerationParameters.NewDocumentName = InvoiceMetadata.Name;
		GenerationParameters.CreateNewDocument = True;
	EndIf;
	ParameterStructureIsNew.Insert("GenerationParameters", GenerationParameters);
	
	Result = TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParameterStructureIsNew, ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtServer
Function FillItOutUsingFillInForm(DocumentsByTypesOfInvoices, ByNotes, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0];
	SelectedRow  = DocumentsTable[0];
	
	InvoiceMetadata = MetadataOfTransactionInvoice(SelectedRow);
	
	If AccessRight("Insert", InvoiceMetadata)
		Or AccessRight("Update", InvoiceMetadata) Then
		
		ReferencesArrray = DocumentsTable.UnloadColumn("Ref");
		
		FormSettings = SettingsOfInvoiceReissueForm(InvoiceMetadata.Name);
		
		HeaderAttributes = New Structure();
		
		TheStructureOfTheSearch = SalesServer.StructureOfMeaningfulProps();
		FillPropertyValues(TheStructureOfTheSearch, SelectedRow);

		DetailsOfOrder = SalesServer.GetOrderDetails(ReferencesArrray);
		TMCommonUseClientServer.SupplementStructure(HeaderAttributes, TheStructureOfTheSearch, True);
		TMCommonUseClientServer.SupplementStructure(HeaderAttributes, DetailsOfOrder, True);

		FormParameters = New Structure();
		FormParameters.Insert("Orders", ReferencesArrray);
		FormParameters.Insert("Warehouse", HeaderAttributes.Warehouse);
		FormParameters.Insert("HeaderAttributes", HeaderAttributes);
		FormParameters.Insert("FormSettings", FormSettings);
		
		FormParametersAndName = New Structure("HasErrors, FormName, Parameters", False);
		
		FormParametersAndName.FormName = "CommonForm.ReregisterInvoicesByReferences";
		FormParametersAndName.Parameters = FormParameters;
		
		Return FormParametersAndName;
	Else
		AccessError = NStr("vi = 'Không có quyền thêm / thay đổi hóa đơn';
							|ru = 'Нет прав на добавление/изменение накладной';
							|en = 'No rights to add/change the invoice'; fa = 'No rights to add/change the invoice';
							|it = 'Nessun diritto per aggiungere / modificare la fattura';
							|pl = 'Brak uprawnień do dodawania / modyfikowania faktury';
							|tr = 'İrsaliye ekleme/değiştirme hakkı yok'");
		CommonClientServer.AddUserError(ErrorList,
			"Object.ListReferencesForRegistration",
			AccessError,
			Undefined);
		
		Return New Structure(); // No rights
	EndIf;
	
EndFunction

&AtServer
Function MetadataOfTransactionInvoice(OperationParametersList)
	
	OrderOperation = OperationParametersList.BusinessOperation;
	
	InvoiceMetadata = Metadata.Documents.ReturnOfGoodsFromCustomer;
	
	If	OrderOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
			Or OrderOperation = Enums.BusinessTransactions.SaleToCustomer Then
		InvoiceMetadata = Metadata.Documents.GoodsReceiptFromCustomer;
	EndIf;
	
	If OrderOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		InvoiceMetadata = Metadata.Documents.ReceiptOfGoodsFromCustodian;
	EndIf;
	
	If OrderOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And ValueIsFilled(OperationParametersList.Contract)
		And Common.ObjectAttributeValue(OperationParametersList.Contract, "ConsignmentSales25") Then
		InvoiceMetadata = Metadata.Documents.ReceiptOfGoodsFromCustodian;
	EndIf;
	
	Return InvoiceMetadata;
	
EndFunction

&AtServer
Function IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices, ByNotes, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0];
	SelectedRow  = DocumentsTable[0];
	
	InvoiceMetadata = MetadataOfTransactionInvoice(SelectedRow);
	InvoiceName        = InvoiceMetadata.Name;
	
	FormSettings = New Structure();
	FormParameters = New Structure();
	
	Orders = DocumentsTable.UnloadColumn("Ref");
	TheStructureOfTheSearch = SalesServer.StructureOfMeaningfulProps();
	
	OrdersWaybills = New Array();
	For Each ReferenceOrder In Orders Do
		
		If TypeOf(ReferenceOrder)= Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or TypeOf(ReferenceOrder)= Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			
			OrdersWaybills.Add(ReferenceOrder);
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Cancel = False;
	If ByNotes And OrdersWaybills.Count() > 0 Then
		// For existing orders-invoices, the header of the document is not refilled
		RefillableInvoice = OrdersWaybills[0];
		FillingValues = New Structure("FillByWarehouseDocument, AnArrayOfOrders", True, Orders);
		
		FormParameters.Insert("FillByWarehouseDocument", ByNotes);
		FormParameters.Insert("AnArrayOfOrders", Orders);
		FormSettings.Insert("FormName", "Document." + InvoiceName + ".Form.DocumentForm");
		
		// To display a message about the number of documents created
		CreatedDocuments.Add(PredefinedValue("Document." + InvoiceMetadata.Name + ".EmptyRef"));
	Else
		
		FillPropertyValues(TheStructureOfTheSearch, SelectedRow);
		
		DetailsOfOrder = SalesServer.GetOrderDetails(Orders);
		HeaderAttributes = New Structure();
		TMCommonUseClientServer.SupplementStructure(HeaderAttributes, TheStructureOfTheSearch, True);
		TMCommonUseClientServer.SupplementStructure(HeaderAttributes, DetailsOfOrder, True);
		
		FormParameters.Insert("FillByWarehouseDocument", ByNotes);
		FormParameters.Insert("HeaderAttributes",    HeaderAttributes);
		FormParameters.Insert("DocumentBasis", Orders);
		FormParameters.Insert("AnArrayOfOrders",     Orders);
		
		FormSettings.Insert("FormName", "Document." + InvoiceName + ".Form.DocumentForm");
		
		// To display a message about the number of documents created
		CreatedDocuments.Add(PredefinedValue("Document." + InvoiceMetadata.Name + ".EmptyRef"));
		
	EndIf;
	
	FormParameters.Insert("CreatedDocuments", CreatedDocuments);
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	If ValueIsFilled(RefillableInvoice) Then
		ParametersWithBase.Insert("FillingValues", FillingValues);
		ParametersWithBase.Insert("Key", RefillableInvoice);
	EndIf;
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	If Cancel Then
		Return Undefined;
	Else
		Return FormSettings;
	EndIf;
	
EndFunction

&AtServer
Function DocumentGenerationParameters()
	
	GenerationParameters = New Structure();
	GenerationParameters.Insert("PrintCustomerInvoice", False);
	GenerationParameters.Insert("PrintTheTransferOfGoodsToBailee", False);
	GenerationParameters.Insert("PrintCustomerInvoiceWorksAndServices", False);
	GenerationParameters.Insert("CreateCashAccountReceiptNote", False);
	GenerationParameters.Insert("CreateSalesDocument", True);
	GenerationParameters.Insert("Warehouse", Warehouse);
	GenerationParameters.Insert("DoNotOpenFormOfCreatedDocument", False);
	GenerationParameters.Insert("ByNotes", ByNotes);
	
	GenerationParameters.Insert(
		"UseSaleByMultipleOrders",
		GetFunctionalOption("UseSaleByMultipleOrders"));
	
	GenerationParameters.Insert(
		"UseCustomerInvoicesForSeveralOrders",
		GetFunctionalOption("UseCustomerInvoicesForSeveralOrders"));
	
	GenerationParameters.Insert(
		"NameOfFormCreatedDocuments",
		"DataProcessor.LogOfSalesDocuments.Form.FormCreatedDocuments");
	GenerationParameters.Insert("ArrangeShipment", False);
	GenerationParameters.Insert("CreateNewDocument", False);
	GenerationParameters.Insert("NameOfShipmentCommand", "");
	GenerationParameters.Insert("NewDocumentName", "");
	
	Return GenerationParameters;
	
EndFunction

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "ToRegisterReturnInvoices";
	
EndFunction

// Returns:
// 	ValueTable:
// * Ref - DocumentRef
// * Partner - CatalogRef.Partners
// * Counterparty - CatalogRef.Counterparties
// * Contract - CatalogRef.CounterpartyContracts
// * Terms - CatalogRef.TermsOfSale
// * Organization - CatalogRef.Companies
// * Warehouse - CatalogRef.Warehouses
// * Department - CatalogRef.BusinessStructure
// * BusinessOperation - EnumRef.BusinessTransactions
// * Currency - CatalogRef.Currencies
// * InvoiceStatus - Number
// * NoteState - Number
&AtServerNoContext
Function SplitTableTemplate_()
	
	SplitTableTemplate = New ValueTable();
	SplitTableTemplate.Columns.Add("Ref", Documents.AllRefsType());
	SplitTableTemplate.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
	SplitTableTemplate.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	SplitTableTemplate.Columns.Add("Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
	SplitTableTemplate.Columns.Add("Terms", New TypeDescription("CatalogRef.TermsOfSale"));
	SplitTableTemplate.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	SplitTableTemplate.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	SplitTableTemplate.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	SplitTableTemplate.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	SplitTableTemplate.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	SplitTableTemplate.Columns.Add("ForeignCurrencyTransaction", New TypeDescription("Boolean"));
	SplitTableTemplate.Columns.Add("InvoiceStatus", New TypeDescription("Number"));
	SplitTableTemplate.Columns.Add("NoteState", New TypeDescription("Number"));
	
	Return SplitTableTemplate;
	
EndFunction

#EndRegion

#EndRegion

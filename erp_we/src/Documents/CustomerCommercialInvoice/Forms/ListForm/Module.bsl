
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager",  Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
	Items.Cancel_2.Visible = AccessRight("Update", Metadata.Documents.CustomerCommercialInvoice);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	State = Settings.Get("State");
	Manager  = Settings.Get("Manager");
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	CommonClientServer.SetDynamicListFilterItem(List, "Manager",  Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager",  Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Cancel_2(Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Được chọn trong sanh sách hóa đơn thanh toán sẽ bị hủy bỏ. Tiếp tục?';
					|ru = 'Выделенные в списке счетов на оплату будут аннулированы. Продолжить?';
					|en = 'Those selected in the list of commercial invoices will be canceled. Continue?'; fa = 'Those selected in the list of commercial invoices will be canceled. Continue?';
					|it = 'Selezionate nell''elenco delle fatture di pagamento saranno annullate. Continuare?';
					|pl = 'Zaznaczone na liście rachunków do zapłaty zostaną anulowane. Kontynuować?';
					|tr = 'Ticari fatura listesinde seçilenler kaldırılacaktır. Devam et?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("Cancel_2Completion", ThisObject), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure Cancel_2Completion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ProcessedItemsCount = SetInvalidFlagServer(Items.List.SelectedRows);
    
    If ProcessedItemsCount > 0 Then
        
        Items.List.Refresh();
        
        MessageText = NStr("vi = '%ProcessedItemsCount% / %TotalCount1% được chọn trong danh sách tài khoản để trả tiền đã hủy';
							|ru = '%ProcessedItemsCount% из %TotalCount1% выделенных в списке счетов на оплату аннулированы.';
							|en = '%ProcessedItemsCount% from %TotalCount1% selected in the list of commercial invoices are canceled.'; fa = '%ProcessedItemsCount% from %TotalCount1% selected in the list of commercial invoices are canceled.';
							|it = '%ProcessedItemsCount% di %TotalCount1% selezionate nell''elenco delle fatture di pagamento sono state annullate.';
							|pl = '%ProcessedItemsCount% z %TotalCount1% zaznaczonych na liście rachunków do zapłaty anulowano.';
							|tr = '%TotalCount1%''dan %ProcessedItemsCount% ticari fatura listesinden seçilenler kaldırılacaktır.'");
        MessageText = StrReplace(MessageText,"%ProcessedItemsCount%", ProcessedItemsCount);
        MessageText = StrReplace(MessageText,"%TotalCount1%",        Items.List.SelectedRows.Count());
        ShowUserNotification(NStr("vi = 'Hóa đơn thanh toán đã hủy';
									|ru = 'Счета на оплату аннулированы';
									|en = 'Commercial invoices are canceled'; fa = 'Commercial invoices are canceled';
									|it = 'Fatture di pagamento sono state annullate';
									|pl = 'Rachunki do zapłaty anulowano';
									|tr = 'Ticari faturalar kaldırılacaktır'"),, MessageText, PictureLib.Information32);
        
    Else
        
        MessageText = NStr("vi = 'Không hủy bất kỳ một hóa đơn thanh toán nào';
							|ru = 'Не аннулирован ни один счет на оплату.';
							|en = 'No commercial invoice is canceled.'; fa = 'No commercial invoice is canceled.';
							|it = 'Nessuna fattura è stata annullata.';
							|pl = 'Nie anulowano ani jednego rachunki do zapłaty.';
							|tr = 'Hiçbir ticari fatura kaldırılmadı.'");
        ShowUserNotification(NStr("vi = 'Hóa đơn thanh toán chưa hủy';
									|ru = 'Счета на оплату не аннулированы';
									|en = 'Commercial invoices are not canceled'; fa = 'Commercial invoices are not canceled';
									|it = 'Fatture di pagamento non sono state annullate';
									|pl = 'Rachunki do zapłaty nie anulowano';
									|tr = 'Ticari faturalar kaldırılmadı'"),, MessageText, PictureLib.Information32);
        
    EndIf;

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ListOfConditionalAppearance = List.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();

	//

	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chọn màu cho hóa đơn có trạng thái ""Đã hủy""';
							|ru = 'Выделение цветом счета в состоянии ""Аннулирован""';
							|en = 'Highlighting the account in the ""Canceled"" state'; fa = 'Highlighting the account in the ""Canceled"" state';
							|it = 'Evidenziazione con un colore della fattura nello stato ""Annullato""';
							|pl = 'Wyróżnienie kolorem konta w stanie ""Anulowane""';
							|tr = '""İptal edildi"" durumundaki hesabın renk ile seçimi'");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CustomerCommercialInvoiceStatuses.Canceled_;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	//
	
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Đặt hình thức thanh toán ""Bất kỳ"" trong trường hợp hình thức thanh toán chưa chỉ ra';
							|ru = 'Установка формы оплаты ""Любая"" в том случае, если она не указана';
							|en = 'Setting the ""Any"" payment method if not specified'; fa = 'Setting the ""Any"" payment method if not specified';
							|it = 'Impostazione della forma di pagamento ""Qualsiasi"" nel caso in cui non fosse indicata';
							|pl = 'Ustawienie formy płatności ""Dowolna"" w tym, jeśli ona nie jest określona';
							|tr = 'Eğer belirtilmediyse ödeme formunun ""Herhangi biri"" olarak ayarlanması'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("PaymentMethod");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bất kỳ';
													|ru = 'Любая';
													|en = 'Any'; fa = 'هر';
													|it = 'Qualsiasi';
													|pl = 'Any';
													|tr = 'Herhangi'"));
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);


EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.CustomerCommercialInvoice.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function SetInvalidFlagServer (Val ProformaInvoices)
	
	Return Documents.CustomerCommercialInvoice.SetInvalidFlag(ProformaInvoices);
	
EndFunction

#EndRegion

#EndRegion

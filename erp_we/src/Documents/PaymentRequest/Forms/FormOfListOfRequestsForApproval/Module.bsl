
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	List.Parameters.SetParameterValue("TheStringFormOfPayment", NStr("vi = 'Tiền mặt hoặc tiền gửi';
																	|ru = 'Наличная или безналичная';
																	|en = 'Cash or bank account'; fa = 'Cash or bank account';
																	|it = 'In contanti o cashless';
																	|pl = 'Gotówkowa lub bezgotówkowa';
																	|tr = 'Nakit veya Elektronik'"));
	
	SetDynamicListSelection();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure PaymentDateSelection_3OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "PayDate", PayDate, DataCompositionComparisonType.LessOrEqual,, ValueIsFilled(PayDate));
		
EndProcedure

&AtClient
Procedure PrioritySelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "PaymentPriority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "HasFiles" Then
		StandardProcessing = False;
		ListLine = Items.List.CurrentData;
		If ListLine <> Undefined Then
			FilesOperationsClient.OpenFileListForm(ListLine.Ref,, ThisObject);
		EndIf;
	EndIf;
	
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

&AtClient
Procedure AutoTestApproveApplications(Command) Export
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If SelectedRows.Count() = 0 Then
		
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Thống nhất giấy đề nghị';
				|ru = 'Согласование заявок';
				|en = 'Application approval'; fa = 'Application approval';
				|it = 'Согласование заявок';
				|pl = 'Application approval';
				|tr = 'Taleplerin mutabakatı'"),
			"Error",
			NStr("vi = 'Không thể thực hiện lệnh với đối tượng đã chỉ ra!';
				|ru = 'Команда не может быть выполнена для указанного объекта!';
				|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
				|it = 'Il comando non può essere eseguito per oggetto indicato!';
				|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
				|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"), ,
			True);
		Return;
		
	EndIf;
	
	ApplicationsForApproval = New Array;
	
	For CurrentIndex = 0 To SelectedRows.UBound() Do
		
		SelectedRow = Items.List.SelectedRows[CurrentIndex];
		
		If Items.List.RowData(SelectedRow).Status = PredefinedValue("Enum.StatusesOfPaymentRequests.NotAgreedUpon") Then
			ApplicationsForApproval.Add(SelectedRow);
		EndIf;
		
	EndDo;
	
	If ApplicationsForApproval.Count() = 0 Then
		
		WarningText = NStr("vi = 'Không thể thống nhất đối với các dòng đã chọn.';
							|ru = 'Согласование не доступно для выделенных строк.';
							|en = 'Approval is unavailable for the selected lines.'; fa = 'Approval is unavailable for the selected lines.';
							|it = 'Согласование не доступно для выделенных строк.';
							|pl = 'Approval is unavailable for the selected lines.';
							|tr = 'Seçilen satırlar için mutabakat mevcut değil.'");
		ShowMessageBox(, WarningText);
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Thống nhất giấy đề nghị';
				|ru = 'Согласование заявок';
				|en = 'Application approval'; fa = 'Application approval';
				|it = 'Согласование заявок';
				|pl = 'Application approval';
				|tr = 'Taleplerin mutabakatı'"),
			"Error",
			WarningText, ,
			True);
		Return;
		
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Đã thống nhất"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""Согласована"". Продолжить?';
					|en = 'Status of the requests selected in the list will be set to Approved. Continue?'; fa = 'Status of the requests selected in the list will be set to Approved. Continue?';
					|it = 'Per le domande selezionate nell''elenco sarà impostato lo stato ""Concordata"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status ""Согласована"". Kontynuować?';
					|tr = 'Başvuru listesinde seçilenlerin durumu ""Kabul Edildi"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("AutoTestApproveApplicationsCompletion", ThisObject, New Structure("SelectedRows", ApplicationsForApproval)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AutoTestApproveApplicationsCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "AgreedUpon");
    
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), "AgreedUpon");

EndProcedure

&AtClient
Procedure RejectRequests(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Hủy bỏ"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""Отклонена"". Продолжить?';
					|en = 'Status of the requests selected in the list will be set to Rejected. Continue?'; fa = 'Status of the requests selected in the list will be set to Rejected. Continue?';
					|it = 'Per le domande selezionate nell''elenco sarà impostato lo stato ""Respinta"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status  ""Отклонена"". Kontynuować?';
					|tr = 'Talep listesinde seçilenlerin durumu ""Reddedildi"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("RejectRequestsCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure RejectRequestsCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "IsRejected");
    
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), "IsRejected");

EndProcedure


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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// Conditional design of the dynamic list "List"
	ListOfConditionalAppearance = List.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	// The document has a high priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentPriority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.PaymentPriorities.GetTopPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	// The document has a low priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên thấp';
							|ru = 'Документ имеет низкий приоритет';
							|en = 'Low priority document'; fa = 'Low priority document';
							|it = 'Il documento ha priorità bassa';
							|pl = 'Dokument ma niski priorytet';
							|tr = 'Belge düşük önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentPriority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.PaymentPriorities.GetLowerPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	// Highlighting an overdue application in color
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách chọn bằng màu đối với giấy đề nghị quá hạn';
							|ru = 'Выделение цветом просроченной заявки';
							|en = 'Highlight overdue request'; fa = 'Highlight overdue request';
							|it = 'Evidenziamento con il colore della domanda scaduta';
							|pl = 'Wyróżnienie kolorem zaległych zleceń';
							|tr = 'Gecikmiş bir talebin vurgu rengi'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("PayDate");
	Item.Fields.Items.Add().Field = New DataCompositionField("RequestIsPaid");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PayDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentSessionDate();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RequestIsPaid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	// Color highlighting of the "Rejected" status
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách chọn bằng màu đối với trạng thái ""Đã hủy""';
							|ru = 'Выделение цветом статуса ""Отклонена""';
							|en = 'Highlight the ""Rejected"" status'; fa = 'Highlight the ""Rejected"" status';
							|it = 'Evidenziamento con il colore dello stato ""Respinta""';
							|pl = 'Wyróżnienie kolorem statusem ""Odrzucona""';
							|tr = '""Reddedildi"" durumunun vurgu rengi'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfPaymentRequests.IsRejected;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "PayDate", PayDate, DataCompositionComparisonType.LessOrEqual,, ValueIsFilled(PayDate));
		
	CommonClientServer.SetDynamicListFilterItem(
		List, "PaymentPriority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

#Region Other

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_PayDate" Then
		PaymentDateSelection_3OnChange(Items.PaymentDateSelection_3);
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

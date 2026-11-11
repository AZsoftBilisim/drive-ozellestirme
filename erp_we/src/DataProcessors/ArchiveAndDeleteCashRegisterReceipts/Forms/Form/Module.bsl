#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Query = New Query(
		"SELECT ALLOWED
		|	MIN(CashRegisterReceipt.Date) AS Date
		|FROM
		|	Document.CashRegisterReceipt AS CashRegisterReceipt
		|WHERE
		|	CashRegisterReceipt.Posted
		|	AND CashRegisterReceipt.CashRegisterShift <> VALUE(Enum.CashRegisterShiftStatuses.IsOpen)");
		
	Result = Query.Execute();
	Selection   = Result.Select();
	If Selection.Next() Then
		StartDate = Selection.Date;
	EndIf;
	
	NumberOfDaysOfReceiptStorage = Constants.NumberOfArchivedReceiptStorageDays.Get() * 86400;
	EndDate = CurrentSessionDate() - NumberOfDaysOfReceiptStorage;
	
	If StartDate > EndDate Then
		StartDate = EndDate;
	EndIf;
	
	UpdateListOfCashRegisterSalesRegisters();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodStartDate_OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	UpdateListOfCashRegisterSalesRegisters();
EndProcedure

&AtClient
Procedure PeriodEndDate_2OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	UpdateListOfCashRegisterSalesRegisters();
EndProcedure

&AtClient
Procedure ProcessingVariantOnChange(Item)
	
	ProcessingOptionOnChangeAtServer(Item.Name);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectDedicatedSalesRegisters(Command)
	RowsArray = Items.CashAccountsTable.SelectedRows;
	SelectDedicatedSalesRegistersOnServer(RowsArray);
EndProcedure

&AtClient
Procedure TheDeletionOfDedicatedCash(Command)
	RowsArray = Items.CashAccountsTable.SelectedRows;
	SelectDedicatedSalesRegistersOnServer(RowsArray, False);
EndProcedure

&AtClient
Procedure ProcessCashReceipts(Command)
	
	ClearMessages();
	
	RowsSelected = CashAccountsTable.FindRows(New Structure("Selected", True));
	ProcessedCashRegisters = New Array;
	For Each TableRow In RowsSelected Do
		If TableRow.ToProcessing > 0 Then
			ProcessedCashRegisters.Add(TableRow.CashRegister);
		EndIf;
	EndDo;
	
	If RowsSelected.Count() = 0 Then		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để xử lý phiếu tính tiền, cần chọn ít nhất một quầy thu ngân.';
				|ru = 'Для обработки чеков ККМ необходимо выбрать хотя бы одну кассу ККМ.';
				|en = 'To process receipts, select at least one cash register.'; fa = 'To process receipts, select at least one cash register.';
				|it = 'Per elaborare gli scontrini di KKM (Macchinari di Registrazione e Controllo) è necessario scegliere almeno una cassa KKM (Macchinari di Registrazione e Controllo).';
				|pl = 'Aby przetworzyć kontrole kasy, musisz wybrać przynajmniej jedną kasę KF.';
				|tr = 'Kasa fişlerini işlemek için en az bir kasa seçilmelidir.'"));
		Return;
	ElsIf ProcessedCashRegisters.Count() = 0 Then
		CommonClientServer.MessageToUser(
			NStr("ru = 'Выберите кассу ККМ, по которой есть чеки ККМ для обработки.';
				|vi = 'Select the cash register that has receipts for processing.';
				|en = 'Select the cash register that has receipts for processing.'; fa = 'Select the cash register that has receipts for processing.';
				|it = 'Select the cash register that has receipts for processing.';
				|pl = 'Select the cash register that has receipts for processing.';
				|tr = 'İşlenecek yazar kasa fişleri olan yazar kasayı seçin.'"));
		Return;
	EndIf;
	CashShiftsForProcessing = FindCashShiftsToProcess(ProcessedCashRegisters, ProcessingVariant);
	If CashShiftsForProcessing.Count() = 0 Then
		CommonClientServer.MessageToUser(
			NStr("ru = 'За указанный период не найдено проведенных кассовых смен для обработки.';
				|vi = 'No POS shifts are found for processing during the specified period.';
				|en = 'No POS shifts are found for processing during the specified period.'; fa = 'No POS shifts are found for processing during the specified period.';
				|it = 'No POS shifts are found for processing during the specified period.';
				|pl = 'No POS shifts are found for processing during the specified period.';
				|tr = 'Belirtilen dönem için işleme yönelik kaydedilmiş POS vardiyası bulunamad'"));
		Return;
	EndIf;
	
	ButtonsList = New ValueList;
	If ProcessingVariant = 1 Then
		QueryText = NStr("vi = 'CHÚ Ý! Tất cả phiếu tính tiền trong kỳ đã chọn sẽ bị xóa. 
			|Điều này có thể mất nhiều thời gian. Xóa phiếu tính tiền?';
			|ru = 'ВНИМАНИЕ! Все чеки ККМ за выбранный период будут удалены. 
			|Это может занять продолжительное время. Удалить чеки ККМ?';
			|en = 'WARNING! All receipts for the selected period will be deleted. 
			|This operation may take a long time. Delete receipts?'; fa = 'WARNING! All receipts for the selected period will be deleted. 
			|This operation may take a long time. Delete receipts?';
			|it = 'ATTENZIONE! Tutti gli scontrini di KKM (Macchinari di Registrazione e Controllo) per il periodo indicato saranno eliminati. 
			|L''operazione può richiedere tempo prolungato. Eliminare gli scontrini di KKM?';
			|pl = 'UWAGA! Wszystkie paragony KF dla wybranego okresu zostaną usunięte. 
			|Może to zająć dużo czasu. Usunąć paragony KF?';
			|tr = 'UYARI! Seçilen döneme ait tüm kasa fişleri silinecektir.
			| Bu işlem uzun sürebilir. Kasa fişlerinizi silmek istiyor musunuz?'");
		ButtonsList.Add("ToProcess", NStr("vi = 'Xóa bỏ';
											|ru = 'Удалить';
											|en = 'Delete'; fa = 'حذف';
											|it = 'Eliminare';
											|pl = 'Delete';
											|tr = 'Sil'"));
	Else
		QueryText = NStr("vi = 'CHÚ Ý! Tất cả phiếu tính tiền trong kỳ đã chọn được lưu trữ. 
			|Điều này có thể mất nhiều thời gian. Lưu trữ phiếu tính tiền?';
			|ru = 'ВНИМАНИЕ! Все чеки ККМ за выбранный период будут заархивированы. 
			|Это может занять продолжительное время. Заархивировать чеки ККМ?';
			|en = 'WARNING! All receipts for the selected period will be archived. 
			|This operation may take a long time. Archive receipts?'; fa = 'WARNING! All receipts for the selected period will be archived. 
			|This operation may take a long time. Archive receipts?';
			|it = 'ATTENZIONE! Tutti gli scontrini di KKM (Macchinari di Registrazione e Controllo) per il periodo selezionato saranno archiviati. 
			| Archiviare gli scontrini di KKM?';
			|pl = 'UWAGA! Wszystkie paragony KF dla wybranego okresu zostaną archiwizowane. 
			|Może to zająć dużo czasu. Archiwizować paragony KF?';
			|tr = 'UYARI! Seçilen döneme ait tüm kasa fişleri arşivlenecektir.
			| Bu işlem uzun sürebilir. Kasa fişlerinizi arşivlemek istiyor musunuz?'");
		ButtonsList.Add("ToProcess", NStr("vi = 'Lưu trữ';
											|ru = 'Заархивировать';
											|en = 'Archive'; fa = 'بایگانی';
											|it = 'Archiviare';
											|pl = 'Archive';
											|tr = 'Arşivlemek'"));
	EndIf;
	ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("CashShiftsForProcessing", CashShiftsForProcessing);
	ShowQueryBox(New CallbackDescription("ProcessCashReceiptsCompletion", ThisObject, ProcessingParameters), QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Dialog = New StandardPeriodEditDialog();
	
	Dialog.Period.StartDate    = StartDate;
	Dialog.Period.EndDate = EndDate;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Dialog = Dialog;
	
	Dialog.Show(New CallbackDescription("SetDateIntervalCompletion", ThisObject, AdditionalParameters));

EndProcedure

// Parameters:
//  Period - StandardPeriod, Undefined -  
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
// 
&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export
	
	Dialog = AdditionalParameters.Dialog;
	If ValueIsFilled(Period) Then
		StartDate    = Dialog.Period.StartDate;
		EndDate = Dialog.Period.EndDate;
		UpdateListOfCashRegisterSalesRegisters();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashAccountsTableCashRegister.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashAccountsTableNumberOfSalesSlipsAccountableFormsPerShift.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CashAccountsTable.NumberOfSalesSlipsAccountableFormsPerShift");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Procedure UpdateListOfCashRegisterSalesRegisters()

	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	CashRegisters.Ref AS CashRegister
		|INTO CashRegisters
		|FROM
		|	Catalog.CashRegisters AS CashRegisters
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT CashRegisterReceipt.Ref) AS NumberOfCashRegisterReceipts,
		|	SUM(CASE
		|			WHEN CashRegisterReceipt.Archived
		|				THEN 0
		|			ELSE 1
		|		END) AS ToArchiving,
		|	SUM(CASE
		|			WHEN CashRegisterReceipt.Archived
		|				THEN 0
		|			ELSE CASE
		|					WHEN CashRegisterReceipt.CashRegisterShift.Posted
		|						THEN 1
		|					ELSE 0
		|				END
		|		END) AS ReadyForArchiving,
		|	SUM(CASE
		|			WHEN CashRegisterReceipt.CashRegisterShift.Posted
		|				THEN 1
		|			ELSE 0
		|		END) AS ReadyToDelete,
		|	CashRegisterReceipt.CashRegister AS CashRegister
		|INTO CashRegisterReceipts
		|FROM
		|	Document.CashRegisterReceipt AS CashRegisterReceipt
		|WHERE
		|	CashRegisterReceipt.CashRegisterShift.Date BETWEEN &StartDate AND &EndDate
		|	AND CashRegisterReceipt.CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
		|
		|GROUP BY
		|	CashRegisterReceipt.CashRegister
		|
		|UNION ALL
		|
		|SELECT
		|	COUNT(DISTINCT CashRegisterReceiptReturn.Ref),
		|	SUM(CASE
		|			WHEN CashRegisterReceiptReturn.CashRegisterReceipt.Archived
		|				THEN 0
		|			ELSE 1
		|		END),
		|	SUM(CASE
		|			WHEN CashRegisterReceiptReturn.CashRegisterReceipt.Archived
		|				THEN 0
		|			ELSE CASE
		|					WHEN CashRegisterReceiptReturn.CashRegisterReceipt.CashRegisterShift.Posted
		|						THEN 1
		|					ELSE 0
		|				END
		|		END),
		|	SUM(CASE
		|			WHEN CashRegisterReceiptReturn.CashRegisterReceipt.CashRegisterShift.Posted
		|				THEN 1
		|			ELSE 0
		|		END),
		|	CashRegisterReceiptReturn.CashRegister
		|FROM
		|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
		|WHERE
		|	CashRegisterReceiptReturn.CashRegisterReceipt.CashRegisterShift.Date BETWEEN &StartDate AND &EndDate
		|	AND CashRegisterReceiptReturn.CashRegisterReceipt.CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
		|
		|GROUP BY
		|	CashRegisterReceiptReturn.CashRegister
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CashRegisters.CashRegister AS CashRegister,
		|	SUM(ISNULL(CashRegisterReceipts.NumberOfCashRegisterReceipts, 0)) AS NumberOfSalesSlipsAccountableFormsPerShift,
		|	SUM(ISNULL(CashRegisterReceipts.ToArchiving, 0)) AS ToArchiving,
		|	SUM(CASE
		|			WHEN &ProcessingVariant = 0
		|				THEN ISNULL(CashRegisterReceipts.ReadyForArchiving, 0)
		|			ELSE ISNULL(CashRegisterReceipts.ReadyToDelete, 0)
		|		END) AS ToProcessing,
		|	MAX(CASE
		|			WHEN CASE
		|					WHEN &ProcessingVariant = 0
		|						THEN CashRegisterReceipts.ReadyForArchiving
		|					ELSE CashRegisterReceipts.ReadyToDelete
		|				END > 0
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS Selected
		|FROM
		|	CashRegisters AS CashRegisters
		|		LEFT JOIN CashRegisterReceipts AS CashRegisterReceipts
		|		ON CashRegisters.CashRegister = CashRegisterReceipts.CashRegister
		|
		|GROUP BY
		|	CashRegisters.CashRegister";
		
	Query.SetParameter("StartDate", BegOfDay(StartDate));
	Query.SetParameter("EndDate", EndOfDay(EndDate));
	Query.SetParameter("ProcessingVariant", ProcessingVariant);
	
	QueryResult = Query.Execute().Unload();
	
	CashAccountsTable.Load(QueryResult);
	
EndProcedure

&AtServer
Procedure SelectDedicatedSalesRegistersOnServer(RowsArray, SelectionValue = True)
	
	For Each RowID In RowsArray Do
		TableRow = CashAccountsTable.FindByID(RowID);
		If TableRow.Selected = (Not SelectionValue) Then
			TableRow.Selected = SelectionValue;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Function FindCashShiftsToProcess(CashRegisterCashAccountsForSearch, ProcessingVariant)
	CashShiftsForProcessing = New Array;
	
	Query = New Query(
	"SELECT ALLOWED
	|	CashRegisterShift.Ref AS Ref	
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|		LEFT JOIN Catalog.CWPSettings.CashRegisters AS CashRegisters
	|		ON CashRegisters.Peripherals = CashRegisterShift.FiscalDevice
	|		AND NOT CashRegisters.UseWithoutConnectingPeripherals
	|WHERE
	|	CashRegisterShift.Posted
	|	AND (CashRegisterShift.CashRegister IN(&CashRegisters) OR CashRegisters.CashRegister IN(&CashRegisters))
	|	AND CashRegisterShift.Date BETWEEN &StartDate AND &EndDate
	|
	|GROUP BY
	|	CashRegisterShift.Ref");
	
	Query.SetParameter("CashRegisters", CashRegisterCashAccountsForSearch);
	Query.SetParameter("StartDate", BegOfDay(StartDate));
	Query.SetParameter("EndDate", EndOfDay(EndDate));
	
	Selection = Query.Execute().Select();	
	While Selection.Next() Do
		CashShiftsForProcessing.Add(Selection.Ref);
	EndDo;
	
	Return CashShiftsForProcessing;
EndFunction

&AtServer
Function ProcessCashShiftsATServer(CashShiftsForProcessing)
	
	JobParameters = RetailSales.NewParametersForCashierShiftClosingTask();
	JobParameters.CashRegisterShift = CashShiftsForProcessing;
	JobParameters.ShowErrorToUser = False;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Xử lý phiếu tính tiền';
														|ru = 'Обработка чеков ККМ';
														|en = 'Receipt processing'; fa = 'Receipt processing';
														|it = 'Elaborazione degli scontrini di KKM (Macchinari di Registrazione e Controllo)';
														|pl = 'Przetwarzanie kontroli KF';
														|tr = 'Kasa fişlerinin işlenmesi'");
	ExecutionParameters.WaitCompletion = 0;
	
	Method = ?(ProcessingVariant = 0, "RetailSales.ExecuteArchiveCashRegisterReceipts",
		"RetailSales.ExecuteDeleteCashRegisterReceipts");
	Result = TimeConsumingOperations.ExecuteInBackground(Method, JobParameters, ExecutionParameters);
		
	Return Result;
	
EndFunction

&AtClient
Procedure ProcessReceiptsNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		UpdateListOfCashRegisterSalesRegisters();
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		NotifyUserOfTaskResults(Result.ResultAddress);
		UpdateListOfCashRegisterSalesRegisters();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessCashReceiptsCompletion(QuestionResult, ProcessingParameters) Export

	UserAnswer = QuestionResult;

	If UserAnswer = "ToProcess" Then
		CallbackOnCompletion = New CallbackDescription("ProcessReceiptsNotification", ThisObject);
		ProcessingResult = ProcessCashShiftsATServer(ProcessingParameters.CashShiftsForProcessing);

		If Not ProcessingResult.Status = "Completed2" Then
			
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			CallbackOnCompletion = New CallbackDescription("ProcessReceiptsNotification", ThisObject);
			
			TimeConsumingOperationsClient.WaitCompletion(
				ProcessingResult, CallbackOnCompletion, IdleParameters);
			
		Else
			RunCallback(CallbackOnCompletion, ProcessingResult);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure NotifyUserOfTaskResults(ResultAddress)
	
	ReceiptProcessingParameters = GetFromTempStorage(ResultAddress);
	
	If Not ReceiptProcessingParameters.ProcessSucceeded Then
		If StandardSubsystemsClient.ClientRunParameters().FileInfobase Then
			ArchivingErrorMessage = NStr("vi = 'Đã hoàn tất lưu trữ phiếu tính tiền có lỗi.';
										|ru = 'Архивация чеков ККМ завершена с ошибками.';
										|en = 'Receipt archiving is completed with errors.'; fa = 'Receipt archiving is completed with errors.';
										|it = 'L''archiviazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è completata con errori.';
										|pl = 'Archiwizacja paragonów KF zakończone z błędami.';
										|tr = 'Kasa fişlerinin arşivlenmesi hatalı olarak tamamlandı.'");
			ErrorMessageDelete  = NStr("vi = 'Đã xóa phiếu tính tiền bị lỗi.';
										|ru = 'Удаление чеков ККМ завершено с ошибками.';
										|en = 'Receipt removal is completed with errors.'; fa = 'Receipt removal is completed with errors.';
										|it = 'L''eliminazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è completata con errori.';
										|pl = 'Usunięcie paragonów KF zakończone z błędami.';
										|tr = 'Kasa fişlerinin silinmesi hatalı olarak tamamlandı.'");
		Else
			ArchivingErrorMessage = NStr("vi = 'Đã hoàn tất lưu trữ phiếu tính tiền có lỗi. Xem nhật ký sự kiện.';
										|ru = 'Архивация чеков ККМ завершена с ошибками. См. журнал регистрации.';
										|en = 'Receipt archiving is completed with errors. See the event log.'; fa = 'Receipt archiving is completed with errors. See the event log.';
										|it = 'L''archiviazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è completata con errori. Vedere il registro.';
										|pl = 'Archiwizacja paragonów KF zakończone z błędami. Patrz dziennik.';
										|tr = 'Kasa fişlerinin arşivlenmesi hatalı olarak tamamlandı. Kayıt defterine bakın.'");
			ErrorMessageDelete  = NStr("vi = 'Đã xóa phiếu tính tiền bị lỗi. Xem trong nhật ký sự kiện.';
										|ru = 'Удаление чеков ККМ завершено с ошибками. См. журнал регистрации.';
										|en = 'Receipts have been deleted with errors. See the event log.'; fa = 'Receipts have been deleted with errors. See the event log.';
										|it = 'L''eliminazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è completata con errori. Vedere il registro.';
										|pl = 'Usunięcie paragonów KF zakończone z błędami. Patrz dziennik.';
										|tr = 'Kasa fişlerinin silinmesi hatalı olarak tamamlandı. Kayıt defterine bakın.'");
		EndIf;
		
		If ProcessingVariant = 0 Then
			ShowUserNotification(NStr("vi = 'Đã hoàn tất lưu trữ.';
										|ru = 'Архивация завершена.';
										|en = 'Archiving is completed.'; fa = 'Archiving is completed.';
										|it = 'L''archiviazione è terminata.';
										|pl = 'Archiwizacja zakończona.';
										|tr = 'Arşivleme işlemi tamamlandı.'"),
				,
				ArchivingErrorMessage,
				PictureLib.Information32);
		ElsIf ProcessingVariant = 1 Then
			ShowUserNotification(NStr("vi = 'Xóa bỏ hoàn tất';
										|ru = 'Удаление завершено.';
										|en = 'Removed.'; fa = 'Removed.';
										|it = 'L''eliminazione è terminata.';
										|pl = 'Usuwanie zakończone.';
										|tr = 'Silme işlemi tamamlandı.'"),
				,
				ErrorMessageDelete,
				PictureLib.Information32);
		EndIf;
		
	Else
		If ProcessingVariant = 0 Then
			ShowUserNotification(NStr("vi = 'Đã hoàn tất lưu trữ.';
										|ru = 'Архивация завершена.';
										|en = 'Archiving is completed.'; fa = 'Archiving is completed.';
										|it = 'L''archiviazione è terminata.';
										|pl = 'Archiwizacja zakończona.';
										|tr = 'Arşivleme işlemi tamamlandı.'"),
				,
				NStr("vi = 'Đã hoàn tất thành công lưu trữ phiếu tính tiền.';
					|ru = 'Архивация чеков ККМ успешно завершена.';
					|en = 'Receipt archiving is completed successfully.'; fa = 'Receipt archiving is completed successfully.';
					|it = 'L''archiviazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è completata con successo.';
					|pl = 'Archiwizacja paragonów KF została pomyślnie zakończona.';
					|tr = 'Kasa fişlerinin arşivlenmesi başarıyla tamamlandı.'"),
				PictureLib.Information32);
		ElsIf ProcessingVariant = 1 Then
			ShowUserNotification(NStr("vi = 'Xóa bỏ hoàn tất';
										|ru = 'Удаление завершено.';
										|en = 'Removed.'; fa = 'Removed.';
										|it = 'L''eliminazione è terminata.';
										|pl = 'Usuwanie zakończone.';
										|tr = 'Silme işlemi tamamlandı.'"),
				,
				NStr("vi = 'Xóa phiếu tính tiền thành công.';
					|ru = 'Удаление чеков ККМ успешно завершено.';
					|en = 'Receipts have been successfully deleted.'; fa = 'Receipts have been successfully deleted.';
					|it = 'L''eliminazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è completata con successo.';
					|pl = 'Usunięcie paragonów KF zostało pomyślnie zakończone.';
					|tr = 'Kasa fişlerinin silinmesi başarıyla tamamlandı.'"),
				PictureLib.Information32);
		EndIf;
	EndIf;
	
EndProcedure

// Function-constructor of additional parameters
// Returns:
// 	Structure - advanced setting:
// * Dialog - StandardPeriodEditDialog, Undefined - 
// 
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("Dialog", Undefined);
	Return Result;
	
EndFunction

&AtServer
Procedure ProcessingOptionOnChangeAtServer(TagName)
	
	UpdateListOfCashRegisterSalesRegisters();
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_StartDate" Then
		PeriodStartDate_OnChange(Items.PeriodStartDate_);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndDate" Then
		PeriodEndDate_2OnChange(Items.PeriodEndDate_2);
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

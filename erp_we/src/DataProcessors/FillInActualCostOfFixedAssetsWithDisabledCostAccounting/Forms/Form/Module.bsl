
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CheckAvailabilityOfDataForProcessing();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInCost(Command)
	
	TimeConsumingOperation = FillInCostOnServer();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AfterCompletingTask", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CheckAvailabilityOfDataForProcessing()
	
	UseCostAccounting = GetFunctionalOption("UseCostAccounting");
	CostAccountingStartDate = Constants.CostAccountingStartDate.Get();
	
	If UseCostAccounting
		And Not ValueIsFilled(CostAccountingStartDate) Then
		
		Items.HelpText.Title = NStr("vi = 'Với kế toán chi phí được bật, không có chi phí được yêu cầu.';
									|ru = 'При включенном учете себестоимости заполнение стоимости не требуется.';
									|en = 'When the cost accounting is off, filling of the cost is not required.'; fa = 'When the cost accounting is off, filling of the cost is not required.';
									|it = 'Quando è abilitata la contabilità dei costi, non è richiesto alcun costo.';
									|pl = 'Gdy ewidencja kosztów własnych jest włączona, wypełnienie wartości nie jest konieczne.';
									|tr = 'Maliyet muhasebesi etkinleştirildiğinde, hiçbir maliyetin doldurulması gerekmez.'");
		Items.FormFillInCost.Enabled = False;
			
		Return; 
	EndIf;
	
	If Not DataProcessors.FillInActualCostOfFixedAssetsWithDisabledCostAccounting.ThereAreDocumentsForProcessing() Then
		
		Items.HelpText.Title = NStr("vi = 'Không có chứng từ cần phải điền vào chi phí.';
									|ru = 'Нет документов, в которых требуется заполнить стоимость.';
									|en = 'No documents where filling of the cost is required.'; fa = 'No documents where filling of the cost is required.';
									|it = 'Non ci sono documenti in cui è richiesto compilare il costo.';
									|pl = 'Brak dokumentów, w których konieczne jest wypełnienie kosztów.';
									|tr = 'Maliyetin doldurulmasını gerektiren herhangi bir evrak yoktur.'");
		Items.FormFillInCost.Enabled = False;
		
		Return;
		
	EndIf;
	
	If UseCostAccounting Then
		
		LabelTitle = NStr("vi = 'Tiến hành kế toán giá vốn từ %1.
                                 |Đã tìm thấy các chứng từ trước ngày mà trong đó giá trị trong chứng từ khác với giá trị thực tế.
                                 |Cần điền giá trị thực tế trong chứng từ theo dữ liệu tính giá trị.';
                                 |ru = 'Учет себестоимости ведется с %1.
                                 |Обнаружены документы до этой даты, в которых стоимость, указанная в документе, отличается от фактической.
                                 |Требуется заполнить фактическую стоимость в документе по данным расчета стоимости.';
                                 |en = 'Cost is accounted since %1.
                                 | Documents before this date are found where the cost specified in the document is different from the actual cost.
                                 |Fill the actual cost in the document by cost calculation data.'; fa = 'Cost is accounted since %1.
                                 | Documents before this date are found where the cost specified in the document is different from the actual cost.
                                 |Fill the actual cost in the document by cost calculation data.';
                                 |it = 'Il calcolo dei costi viene eseguita dal %1.
                                 |Prima di questa data sono stati rilevati i documenti in cui il costo indicato nel documento differisce da quello effettivo.
                                 |Richiesto per compilare il costo effettivo nel documento in base al calcolo del costo.';
                                 |pl = 'Ewidencja kosztów własnych jest przeprowadzana z %1.
                                 |Dokumenty znajdują się przed tą datą, w której koszt określony w dokumencie różni się od rzeczywistej wartości.
                                 |Wymagany jest faktyczny koszt w dokumencie zgodnie z danymi kalkulacji kosztów wartości.';
                                 |tr = '%1İle maliyet muhasebesi yapılmaktadır.
                                 |Bu tarihten önceki belgelerde, belgede belirtilen değerin gerçek olandan farklı olduğu tespit edilmiştir.
                                 |Hesaplama verilerine göre belgedeki fiili maliyetin doldurulması gerekmektedir.'");
		
		LabelTitle = StrTemplate(LabelTitle, Format(CostAccountingStartDate, "DLF=D"));
		
	Else
		
		LabelTitle = NStr("vi = 'Đã ngắt kế toán giá vốn.
                                 |Đã tìm thấy các chứng từ mà trong đó giá trị trong chứng từ khác với giá trị thực tế.
                                 |Cần điền giá trị thực tế trong chứng từ theo dữ liệu tính giá trị.';
                                 |ru = 'Учет себестоимости отключен.
                                 |Обнаружены документы, в которых стоимость, указанная в документе, отличается от фактической.
                                 |Требуется заполнить фактическую стоимость в документе по данным расчета стоимости.';
                                 |en = 'Cost accounting is off.
                                 |Documents where the cost specified in the document is different from the actual cost are found.
                                 |Fill the actual cost in the document by cost calculation data.'; fa = 'Cost accounting is off.
                                 |Documents where the cost specified in the document is different from the actual cost are found.
                                 |Fill the actual cost in the document by cost calculation data.';
                                 |it = 'Disabilitare il calcolo del costo di produzione.
                                 |Prima di questa data sono stati rilevati i documenti in cui il costo indicato nel documento differisce da quello effettivo.
                                 |Richiesto per compilare il costo effettivo nel documento in base al calcolo del costo.';
                                 |pl = 'Ewidencja kosztów własnych jest wyłączona.
                                 |Znaleziono dokumenty, w których koszt, określony w dokumencie, różni się od rzeczywistego kosztu.
                                 |Wymagane jest wypełnienie rzeczywistego kosztu w dokumencie zgodnie z danymi kalkulacji kosztów.';
                                 |tr = 'Maliyet muhasebesi devre dışıdır. 
                                 | Belgede belirtilen maliyetin gerçek maliyetten farklı olduğu belgeler tespit edildi. 
                                 |Maliyet hesaplama verilerine dayalı olarak belgedeki gerçek maliyeti doldurmanız gerekir.'");
		
	EndIf; 
	
	Items.HelpText.Title = LabelTitle;
	
	Items.FormFillInCost.Enabled = True;
	
EndProcedure

&AtServer
Function FillInCostOnServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = 
		Metadata.DataProcessors.FillInActualCostOfFixedAssetsWithDisabledCostAccounting.Synonym;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.FillInActualCostOfFixedAssetsWithDisabledCostAccounting.FillInCost",
		New Structure,
		BackgroundExecutionParameters);
	
	Return Result;
	
EndFunction

&AtClient
Procedure AfterCompletingTask(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.MessageToUser(Result.BriefErrorDescription);
		Return;
	EndIf;
	
	AfterCompletingTaskOnServer(Result.ResultAddress);
	
EndProcedure

&AtServer
Procedure AfterCompletingTaskOnServer(ResultAddress)

	If IsTempStorageURL(ResultAddress) Then
		
		ErrorText = GetFromTempStorage(ResultAddress);
		
		If ErrorText <> Undefined Then
			
			LabelTitle = NStr("vi = 'Khi điền giá trị, đã xảy ra lỗi:
                                     |%1';
                                     |ru = 'При заполнении стоимости возникла ошибка:
                                     |%1';
                                     |en = 'While the cost is being filled in, the error occurred:
                                     |%1'; fa = 'While the cost is being filled in, the error occurred:
                                     |%1';
                                     |it = 'Si è verificato un errore durante l''esecuzione del calcolo:
                                     |%1';
                                     |pl = 'Podczas wypełniania wartości wystąpił błąd:
                                     |%1';
                                     |tr = 'Maliyet doldurulurken bir hata oluştu:
                                     |%1'");
			
			LabelTitle = StrTemplate(LabelTitle, ErrorText);
			Items.HelpText.Title = LabelTitle;
			
			Return;
		EndIf; 
		
	EndIf; 
	
	CheckAvailabilityOfDataForProcessing();

EndProcedure

#EndRegion

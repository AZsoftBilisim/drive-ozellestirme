
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CheckForUnusedRegisteredRecords();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ClearRegisteredRecords(Command)
	
	TimeConsumingOperation	= ClearUnusedRegisteredRecordsInCostRegisters();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("vi = 'Đang thực hiện xóa bản ghi kết chuyển.';
										|ru = 'Выполняется очистка движений.';
										|en = 'Movements are being cleared.'; fa = 'Movements are being cleared.';
										|it = 'Viene eseguita la cancellazione dei movimenti.';
										|pl = 'Wykonywane jest usuwanie ruchów.';
										|tr = 'Temizleme hareketleri gerçekleştirilir.'");
	
	CallbackOnCompletion = New CallbackDescription("ClearRegisteredRecordsCompletion", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		CallbackOnCompletion,
		IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CheckForUnusedRegisteredRecords()
	
	DocumentsCount = DataProcessors.ClearingPostingsWithDisabledCostAccounting.NumberOfRecordersWithUnusedRegisteredRecords();
	
	If DocumentsCount = 0 Then
		
		Items.HelpText.Title = NStr("vi = 'Khi ngắt kế toán giá vốn, không có chứng từ với bản ghi kết chuyển theo biểu ghi kế toán giá vốn.';
									|ru = 'При отключеном учете себестоимости отсутствуют документы с движениями по регистрам учета себестоимости.';
									|en = 'When the cost accounting is off, there are no documents with records by cost accounting registers.'; fa = 'When the cost accounting is off, there are no documents with records by cost accounting registers.';
									|it = 'Quando il calcolo dei costi è disabilitato, non ci sono documenti con movimenti sui registri di contabilità dei costi.';
									|pl = 'Gdy księgowanie kosztów własnych jest wyłączone, nie ma dokumentów zawierających ruchy w rejestrach księgowania kosztów własnych.';
									|tr = 'Maliyet muhasebesi devre dışı bırakıldığında, maliyet muhasebesi kayıtlarında hareket içeren hiçbir belge bulundu.'");
		
		Items.FormClearRegisteredRecords.Enabled = False;
		
		Return;
		
	EndIf;
	
	TextTemplate1 = NStr("vi = 'Kế toán giá vốn bắt đầu từ kỳ %1.
	|Khi vô hiệu hóa kế toán giá vốn đã tìm thấy chứng từ có bản ghi kết chuyển theo biểu ghi kế toán giá vốn: %2.
	|Việc xóa các bản ghi kết chuyển của chứng từ này có thể mất nhiều thời gian.';
	|ru = 'Учет себестоимости ведется начиная с периода %1.
	|При отключеном учете себестоимости найдены документы с движениями по регистрам учета себестоимости: %2.
	|Очистка движений этих документов может занять продолжительное время.';
	|en = 'The cost is accounted since the period %1.
	|When the cost accounting is off, documents with records by cost accounting registers are found: %2.
	|It may take some time to clear records of this documents.'; fa = 'The cost is accounted since the period %1.
	|When the cost accounting is off, documents with records by cost accounting registers are found: %2.
	|It may take some time to clear records of this documents.';
	|it = 'Il calcolo del costo di produzione viene eseguito partendo dal periodo%1.
	|Quando la contabilità dei costi è stata disattivata, i documenti sono stati trovati con movimenti in base ai registri di contabilità dei costi: %2.
	|La cancellazione dei movimenti di questi documenti può occupare molto tempo.';
	|pl = 'Ewidencja kosztów własnych jest przeprowadzana z %1.
	|Przy wyłączonej ewidencji kosztów własnych, dokumenty z ruchami zostały znalezione w rejestrach ewidencji kosztów własnych:%2.
	|Usunięcie ruchów tych dokumentów może zająć sporo czasu.';
	|tr = 'Maliyet muhasebesi %1 döneminden başlayarak yürütülür.
	|Maliyet muhasebesi devre dışı bırakıldığında, maliyet muhasebesi kayıtlarında hareketleri olan belgeler bulundu: %2.
	|Bu belgelerin hareketlerinin temizlenmesi uzun zaman alabilir.'");
	
	Items.HelpText.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TextTemplate1,
		CostCalculationProtocol.PresentationOfCalculationPeriod(Constants.CostAccountingStartDate.Get()),
		Format(DocumentsCount, "NG="));
	
	Items.FormClearRegisteredRecords.Enabled = True;
	
EndProcedure

&AtServer
Function ClearUnusedRegisteredRecordsInCostRegisters()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription =
		Metadata.DataProcessors.ClearingPostingsWithDisabledCostAccounting.Synonym;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ClearingPostingsWithDisabledCostAccounting.ClearUnusedRegisteredRecordsInCostRegisters",
		"",
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ClearRegisteredRecordsCompletion(Result, AdditionalParameters) Export
	
	CheckForUnusedRegisteredRecords();
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Writes data to a register.
//
// Parameters:
//  Queue	- ValueTable - data to be written.
//  StandardCostEstimate - DocumentRef.StandardCosting2_2 - the document that the queue belongs to.
//
Procedure WriteQueue(Queue, StandardCostEstimate) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
	
		LockItem = Block.Add("InformationRegister.CalculationQueueOfStandardCostEstimates");
		LockItem.SetValue("StandardCostEstimate", StandardCostEstimate);
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		Separator = QueueSeparator(StandardCostEstimate);
		
		Queue.Columns.Add("Separator");
		Queue.FillValues(Separator, "Separator");
		
		RecordSet = InformationRegisters.CalculationQueueOfStandardCostEstimates.CreateRecordSet();
		RecordSet.Filter.StandardCostEstimate.Set(StandardCostEstimate);
		RecordSet.Filter.Separator.Set(Separator);
		RecordSet.Load(Queue);
		
		SetPrivilegedMode(True);
		RecordSet.Write();
		SetPrivilegedMode(False);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		RecordSet = InformationRegisters.CalculationQueueOfStandardCostEstimates.CreateRecordSet();
		
		MessageText = NStr("vi = 'Không thể ghi hàng đợi tính toán kế hoạch: %Ref% vì lý do: %Cause%';
							|ru = 'Не удалось записать очередь расчета плана: %Ref% по причине: %Cause%';
							|en = 'Cannot save plan calculation queue: %Ref%. Reason: %Cause%'; fa = 'Cannot save plan calculation queue: %Ref%. Reason: %Cause%';
							|it = 'Non è stato possibile registrare la coda di pagamento del piano: %Ref% a causa di: %Cause%';
							|pl = 'Nie udało się zapisać kolejki obliczania planu: %Ref% z powodu: %Cause%';
							|tr = 'Plan hesaplama sırası: %Ref% bu sebepten dolayı kaydedilmedi: %Cause%'");
		MessageText = StrReplace(MessageText, "%Ref%", StandardCostEstimate);
		MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(
			ErrorInfo()));
		
		WriteLogEvent(
			EventLogEvent(),
			EventLogLevel.Error,
			RecordSet.Metadata(),
			,
			MessageText);
		
		Raise;
			
	EndTry;
	
EndProcedure

// Clears the register data for the specified dimensions.
//
// Parameters:
//  StandardCostEstimate - DocumentRef.StandardCosting2_2 - the document that the queue belongs to.
//  Queue	- ValueTable - measurement data for cleaning, in case it is necessary to clear the entire queue, can be transferred Indefinitely.
//
Procedure ClearQueue(StandardCostEstimate, Queue = Undefined) Export
	
	SetPrivilegedMode(True);
	If Queue = Undefined Then
		Query = New Query;
		Query.Text = 
			"SELECT
			|	Queue.StandardCostEstimate AS StandardCostEstimate,
			|	Queue.LotProductBOM AS LotProductBOM,
			|	Queue.ManufacturedProduct AS ManufacturedProduct,
			|	Queue.ItemVariant AS ItemVariant,
			|	Queue.Purpose AS Purpose,
			|	Queue.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
			|	Queue.KeyLot AS KeyLot,
			|	Queue.SemiFinishedProduct AS SemiFinishedProduct,
			|	Queue.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
			|	Queue.Separator AS Separator,
			|	Queue.DemandDate AS DemandDate,
			|	Queue.Order AS Order
			|FROM
			|	InformationRegister.CalculationQueueOfStandardCostEstimates AS Queue
			|WHERE
			|	Queue.StandardCostEstimate = &StandardCostEstimate";
		
		Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
		Queue = Query.Execute().Unload();
	EndIf;
	
	For Each String In Queue Do
		
		RecordSet = InformationRegisters.CalculationQueueOfStandardCostEstimates.CreateRecordSet();
		
		For Each Column In Queue.Columns Do
			
			Dimension = RecordSet.Filter[Column.Name]; // FilterItem
			Dimension.Set(String[Column.Name]);
			
		EndDo;
		
		Try
			RecordSet.Write();
		Except
			
			RecordSet = InformationRegisters.CalculationQueueOfStandardCostEstimates.CreateRecordSet();
			
			MessageText = NStr("vi = 'Không thể xóa hàng đợi tính toán kế hoạch: %Ref% vì lý do: %Cause%';
								|ru = 'Не удалось очистить очередь расчета плана: %Ref% по причине: %Cause%';
								|en = 'Cannot clear plan calculation queue: %Ref%. Reason: %Cause%'; fa = 'Cannot clear plan calculation queue: %Ref%. Reason: %Cause%';
								|it = 'Non è stato possibile cancellare la coda di pagamento del piano: %Ref% a causa di: %Cause%';
								|pl = 'Nie udało się wyczyścić kolejki obliczania planu: %Ref% z powodu: %Cause%';
								|tr = 'Plan hesaplama sırası: %Ref% bu sebepten dolayı temizlenemedi: %Cause%'");
			MessageText = StrReplace(MessageText, "%Ref%", StandardCostEstimate);
			MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
			
			WriteLogEvent(
				EventLogEvent(),
				EventLogLevel.Error,
				RecordSet.Metadata(),
				,
				MessageText);
			
			Raise;
			
		EndTry;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

#Region Other

Function QueueSeparator(StandardCostEstimate)
	
	Separator = 1;
	
	Query = New Query;
	Query.SetParameter("Ref", StandardCostEstimate);
	Query.Text = 
		"SELECT TOP 1
		|	ISNULL(MAX(Queue.Separator), 0) AS Separator
		|FROM
		|	InformationRegister.CalculationQueueOfStandardCostEstimates AS Queue
		|WHERE
		|	Queue.StandardCostEstimate = &Ref";
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		Separator = SelectionDetailRecords.Separator + 1;
	EndIf;
	
	Return Separator;
	
EndFunction

Function EventLogEvent()
	
	Return NStr("vi = 'Ghi lại hàng đợi để tính giá thành sản phẩm';
				|ru = 'Запись очереди расчета калькуляции продукции';
				|en = 'Save product costing calculation queue'; fa = 'Save product costing calculation queue';
				|it = 'Registrazione della coda di pagamento del calcolo della produzione';
				|pl = 'Zapis kolejki obliczania kalkulacji produkcji';
				|tr = 'İmal edilen ürün maliyetinin hesaplanması için sıranın kaydı'", CommonClientServer.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndIf

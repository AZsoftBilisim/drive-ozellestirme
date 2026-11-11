#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	TMCommonUse.CollapseRecordSet(ThisObject, True);
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
		
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;

	ComplianceOfOperations = WarehousesClientServer.ComplianceOfEconomicOperationsWithWarehouseAcceptanceOperations();
	
	For Each SetRow_ In ThisObject Do
		Operation = ComplianceOfOperations.Get(SetRow_.BusinessOperation);
		If Operation = Undefined Then
			MessageText = NStr("vi = 'Không hỗ trợ phản ánh giao dịch kinh tế ""%BusinessOperation%"" vào biểu ghi %GoodsToReceive%. Hãy liên hệ với nhà phát triển.';
								|ru = 'Отражение хозяйственной операции ""%BusinessOperation%"" в регистр %GoodsToReceive% не поддерживается. Обратитесь к разработчикам.';
								|en = 'Cannot record the ""%BusinessOperation%"" business transaction to the %GoodsToReceive% register. Contact the developers.'; fa = 'Cannot record the ""%BusinessOperation%"" business transaction to the %GoodsToReceive% register. Contact the developers.';
								|it = 'La visualizzazione della transazione economica ""%BusinessOperation%"" nel registro %GoodsToReceive% non è supportata. Contattare programmatori.';
								|pl = 'Odzwierciedlenie operacji gospodarczej „%BusinessOperation%” w rejestrze %GoodsToReceive% nie jest obsługiwane. Skontaktuj się z twórcami programu.';
								|tr = '%GoodsToReceive%siciline ""%BusinessOperation%"" ticari işleminin yansıtılması desteklenmiyor. Geliştiriciye başvur.'");
			MessageText = StrReplace(MessageText, "%GoodsToReceive%", "GoodsToReceive");
			MessageText = StrReplace(MessageText,"%BusinessOperation%", SetRow_.BusinessOperation);  
			CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		ElsIf Operation <> Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions
			And Not ValueIsFilled(SetRow_.Sender) Then
			MessageText = NStr("vi = 'Chỉ hỗ trợ ghi lại người gửi trống trong biểu ghi %GoodsToReceive% đối với giao dịch kho bãi %WarehouseOperation%. Hãy liên hệ với nhà phát triển.';
								|ru = 'Запись пустого отправителя в регистр %GoodsToReceive% поддерживается только для складской операции %WarehouseOperation%. Обратитесь к разработчикам.';
								|en = 'Saving an empty sender to the %GoodsToReceive% register is supported only for the %WarehouseOperation% warehouse operation. Contact the developers.'; fa = 'Saving an empty sender to the %GoodsToReceive% register is supported only for the %WarehouseOperation% warehouse operation. Contact the developers.';
								|it = 'La registrazione di un mittente vuoto nel registro %GoodsToReceive% è supportata solo per operazione di magazzino %WarehouseOperation%. Contattare programmatori.';
								|pl = 'Zapisywanie pustej przesyłki do rejestru %GoodsToReceive% jest obsługiwane tylko dla operacji magazynowej %WarehouseOperation%. Skontaktuj się z twórcami programu.';
								|tr = '%GoodsToReceive%siciline boş gönderen kaydı %WarehouseOperation%ambar işlemi için destekleniyor. Geliştiriciye başvur.'");
			MessageText = StrReplace(MessageText, "%GoodsToReceive%", "GoodsToReceive");
			MessageText = StrReplace(MessageText,"%WarehouseOperation%", Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions);  
			CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		EndIf
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.DocumentInflow AS DocumentInflow,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	Table.Warehouse AS Warehouse,
	|	Table.Sender AS Sender,
	|	Table.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToRegisterInvoicesByReference
	|		ELSE -Table.ToRegisterInvoicesByReference
	|	END AS ToRegisterInvoicesByReferenceBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToRegisterReceiptsByReference
	|		ELSE -Table.ToRegisterReceiptsByReference
	|	END AS ToRegisterReceiptsByReferenceBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToRegisterReceiptsByInvoices
	|		ELSE -Table.ToRegisterReceiptsByInvoices
	|	END AS ToRegisterReceiptsByInvoicesBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToRegisterGoodsReceipts
	|		ELSE -Table.ToRegisterGoodsReceipts
	|	END AS ToRegisterGoodsReceiptsBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.GoodsReceiptNotesToRegister
	|		ELSE -Table.GoodsReceiptNotesToRegister
	|	END AS GoodsReceiptNotesToRegisterBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.Accepts
	|		ELSE -Table.Accepts
	|	END AS AcceptsBeforeWrite
	|INTO GoodsToReceiveBeforeWrite
	|FROM
	|	AccumulationRegister.GoodsToReceive AS Table
	|WHERE
	|	Table.Recorder = &Recorder";
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load 
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	ChangesTable.DocumentInflow AS DocumentInflow,
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Purpose AS Purpose,
	|	ChangesTable.Series AS Series,
	|	ChangesTable.Warehouse AS Warehouse,
	|	ChangesTable.Sender AS Sender,
	|	ChangesTable.BusinessOperation AS BusinessOperation,
	|	SUM(ChangesTable.ToRegisterInvoicesByReferenceUpdate) AS ToRegisterInvoicesByReferenceUpdate,
	|	SUM(ChangesTable.ToRegisterReceiptsByReferenceUpdate) AS ToRegisterReceiptsByReferenceUpdate,
	|	SUM(ChangesTable.ToRegisterReceiptsByInvoicesUpdate) AS ToRegisterReceiptsByInvoicesUpdate,
	|	SUM(ChangesTable.ToRegisterGoodsReceiptsUpdate) AS ToRegisterGoodsReceiptsUpdate,
	|	SUM(ChangesTable.GoodsReceiptNotesToRegisterUpdate) AS GoodsReceiptNotesToRegisterUpdate,
	|	SUM(ChangesTable.AcceptsUpdate) AS AcceptsUpdate
	|INTO GoodsToReceiveUpdate
	|FROM
	|	(SELECT
	|		Table.DocumentInflow AS DocumentInflow,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		Table.Sender AS Sender,
	|		Table.BusinessOperation AS BusinessOperation,
	|		Table.ToRegisterInvoicesByReferenceBeforeWrite AS ToRegisterInvoicesByReferenceUpdate,
	|		Table.ToRegisterReceiptsByReferenceBeforeWrite AS ToRegisterReceiptsByReferenceUpdate,
	|		Table.ToRegisterReceiptsByInvoicesBeforeWrite AS ToRegisterReceiptsByInvoicesUpdate,
	|		Table.ToRegisterGoodsReceiptsBeforeWrite AS ToRegisterGoodsReceiptsUpdate,
	|		Table.GoodsReceiptNotesToRegisterBeforeWrite AS GoodsReceiptNotesToRegisterUpdate,
	|		Table.AcceptsBeforeWrite AS AcceptsUpdate
	|	FROM
	|		GoodsToReceiveBeforeWrite AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.DocumentInflow AS DocumentInflow,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		Table.Sender AS Sender,
	|		Table.BusinessOperation AS BusinessOperation,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToRegisterInvoicesByReference
	|			ELSE Table.ToRegisterInvoicesByReference
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToRegisterReceiptsByReference
	|			ELSE Table.ToRegisterReceiptsByReference
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToRegisterReceiptsByInvoices
	|			ELSE Table.ToRegisterReceiptsByInvoices
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToRegisterGoodsReceipts
	|			ELSE Table.ToRegisterGoodsReceipts
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.GoodsReceiptNotesToRegister
	|			ELSE Table.GoodsReceiptNotesToRegister
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.Accepts
	|			ELSE Table.Accepts
	|		END
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.DocumentInflow,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.Series,
	|	ChangesTable.Warehouse,
	|	ChangesTable.Sender,
	|	ChangesTable.BusinessOperation
	|
	|HAVING
	|	(SUM(ChangesTable.ToRegisterInvoicesByReferenceUpdate) <> 0
	|		OR SUM(ChangesTable.ToRegisterReceiptsByReferenceUpdate) <> 0
	|		OR SUM(ChangesTable.ToRegisterReceiptsByInvoicesUpdate) <> 0
	|		OR SUM(ChangesTable.ToRegisterGoodsReceiptsUpdate) <> 0
	|		OR SUM(ChangesTable.GoodsReceiptNotesToRegisterUpdate) <> 0
	|		OR SUM(ChangesTable.AcceptsUpdate) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsToReceiveBeforeWrite";
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
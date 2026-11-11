#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Ref = Parameters.Ref;
	
	LinkDetails_ = Common.ObjectAttributesValues(
		Ref,
		"Count,FollowUp,QuantityUnderRevision,DefectiveGoodsCount,CountReal,CountCanceled,Department, Operation.UnitOfMeasure");
	
	Count = LinkDetails_.Count - LinkDetails_.CountCanceled;
	
	Department = LinkDetails_.Department;
	
	Items.Count.MaxValue = Count;
	Items.Count.MinValue  = LinkDetails_.FollowUp
		+ LinkDetails_.QuantityUnderRevision
		+ LinkDetails_.DefectiveGoodsCount
		+ LinkDetails_.CountReal;
	
	UnitOfMeasureOperation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		LinkDetails_.OperationUnitOfMeasure,
		,
		True);
		
	Items.RecordFailureToExecute.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phản ánh sự thất bại của hoạt động với số tiền 0 %1';
			|ru = 'Отразить невыполнение операции в количестве 0 %1';
			|en = 'Record the operation failure in the amount of 0 %1'; fa = 'Record the operation failure in the amount of 0 %1';
			|it = 'Rilevare operazioni non effettuate in quantità 0%1';
			|pl = 'Odzwierciedlić niewykonane operacje w ilości 0%1';
			|tr = '%1 0 miktarında işlemin gerçekleştirilememesini yansıt'"),
		UnitOfMeasureOperation);
	
	SetStatus();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	If Count < Items.Count.MaxValue And Count > 0 Then
		
		WriteAndCloseOnServer(Ref, Count, NewTransactionStatus);
		ProductionAccountingClient.NotifyAboutRecordingOfProductionOperations(Department,, Ref);
		
		Close();
		
	Else
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Số lượng nhập không chính xác';
							|ru = 'Введено неверное количество';
							|en = 'Invalid number entered'; fa = 'Invalid number entered';
							|it = 'Quantità inserita non è corretta';
							|pl = 'Nieprawidłowa ilość';
							|tr = 'Geçersiz miktar girildi'");
		Message.Message();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteAndCloseOnServer(Ref, Completed2, NewStatus_)
	Documents.ProductionOperation2_2.ExecutePartially(Ref, Completed2, NewStatus_);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountOnChange(Item)
	
	QuantityLeft = Items.Count.MaxValue - Count;
	
	Items.RecordFailureToExecute.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phản ánh sự thất bại của hoạt động với số tiền %1 %2';
			|ru = 'Отразить невыполнение операции в количестве %1 %2';
			|en = 'Record the operation failure in the amount of %1%2'; fa = 'Record the operation failure in the amount of %1%2';
			|it = 'Rilevare operazioni non effettuate in quantità %1%2';
			|pl = 'Odzwierciedlić niewykonane operacje w ilości %1 %2';
			|tr = '%2 %1 miktarında işlemin gerçekleştirilememesini yansıt'"),
		QuantityLeft,
		UnitOfMeasureOperation);
		
EndProcedure

&AtClient
Procedure RecordFailureToExecuteOnChange(Item)
	SetStatus();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetStatus()
	
	Status = Common.ObjectAttributeValue(Ref, "Status");
	
	If Status = Enums.ProductionOperationStatuses.Running Then
		CurrentStatus = "Running";
	ElsIf Status = Enums.ProductionOperationStatuses.CreatedOn_ Then
		CurrentStatus = "CreatedOn_";
	EndIf;
	
	NewTransactionStatus = ?(RecordFailureToExecute, "NotExecuted", CurrentStatus);
	
EndProcedure


#EndRegion

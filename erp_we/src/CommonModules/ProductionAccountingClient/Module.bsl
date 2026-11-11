////////////////////////////////////////////////////////////////////////////////
// OUP: Procedures of the subsystem of operational accounting of production
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


// Draws up a document for employees on the basis of orders
//
// Parameters:
//  ListOfOrders_	- Array - list of orders.
//
Procedure IssueDevelopmentOfEmployeesOnOrders(ListOfOrders_) Export
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("References", ListOfOrders_);
	
	DesignParameters = ProductionAccountingServerCall.DesignParametersForEmployees(FilterStructure1);
	
	If DesignParameters = Undefined Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Theo lệnh đã chọn, đã tạo sản lượng của nhân viên, không cần tạo hoặc sản lượng không khả dụng.';
				|ru = 'По выбранным распоряжениям выработка сотрудников уже оформлена, оформление не требуется или не доступна.';
				|en = 'Timesheets charge for the selected references is already registered. Registration is not required or unavailable.'; fa = 'Timesheets charge for the selected references is already registered. Registration is not required or unavailable.';
				|it = 'Per le disposizioni selezionate, la produttività dei dipendenti è già compilata, la registrazione non è richiesta oppure non è disponibile.';
				|pl = 'Według wybranych zamówień wydajność pracowników jest już utworzona, utworzenie nie jest wymagane lub jest niedostępna.';
				|tr = 'Seçili talimatlara göre zaman çizelgesi bazlı ücretlendirmesi zaten düzenlenmiş, düzenleme gerekli veya mevcut değil.'"));
		Return;
	EndIf;
	
	If DesignParameters.OneDocumentIsRequired Then
		
		DesignParameters.Insert("FillInByPicking", True);
		
		FormParameters = New Structure("FillingValues", DesignParameters);
		OpenForm("Document.WorkOutput.ObjectForm", FormParameters);
		
	Else
		
		Result = ProductionAccountingServerCall.FormDevelopmentOfSelectionStaff(DesignParameters);
		
		If Result.DocumentsCount > 0 Then
			OpenForm("Document.WorkOutput.Form.NewDocumentListForm",
				Result,,,,,);
		Else
			CommonClientServer.MessageToUser(
				NStr("vi = 'Không thể hoàn thành việc phát triển các đơn hàng đã chọn. Bắt buộc phải vào biểu mẫu ""Đăng ký"" và tạo chứng từ theo cách thủ công.';
					|ru = 'Не удалось оформить выработку по выбранным распоряжениям. Требуется перейти в форму ""К оформлению"" и создать документы вручную.';
					|en = 'Cannot register output by selected references. Go to the ""For registration"" form and create documents manually.'; fa = 'Cannot register output by selected references. Go to the ""For registration"" form and create documents manually.';
					|it = 'Non è stato possibile regolarizzare la produttività per le disposizioni selezionate. È necessario passare al form ""Da regolarizzare"" e creare i documenti manualmente.';
					|pl = 'Nie udało się sporządzić wytwarzanie wg wybranych zamówień. Trzeba przejść do formularza ""Do sporządzenia"" i utworzyć dokumenty ręcznie.';
					|tr = 'Seçili talimatlara göre işçilik ücretlendirmesi düzenlenemedi. ""Düzenlenecek"" formuna gidip belgeleri manuel olarak oluşturmanız gerekmektedir.'"));
		EndIf;
		
	EndIf;
	
EndProcedure

// Draws up a document of employee development based on shift tasks
//
// Parameters:
//  ListOfShiftTasks	- Array - a list of replacement jobs.
//
Procedure IssueDevelopmentOfEmployeesOnShiftAssignment(ListOfShiftTasks) Export
	
	DesignParameters = ProductionAccountingServerCall.ParametersForProcessingEmployeesWorkOnShiftAssignments(
		ListOfShiftTasks);
	
	If DesignParameters = Undefined Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Theo các đơn đặt hàng đã chọn, sự phát triển của nhân viên đã được ban hành hoặc không cần đăng ký.';
				|ru = 'По выбранным распоряжениям выработка сотрудников уже оформлена или оформление не требуется.';
				|en = 'Timesheets charge for the selected references has already been registered or registration is not required.'; fa = 'Timesheets charge for the selected references has already been registered or registration is not required.';
				|it = 'Per le disposizioni selezionate, la produttività dei dipendenti è già stata formalizzata o la formalizzazione non è richiesta.';
				|pl = 'Wg wybranych zamówień wytwarzanie pracowników już jest sporządzone lub sporządzenie nie jest wymagane.';
				|tr = 'Seçili talimatlara göre zaman çizelgesi bazlı ücretlendirmesi zaten düzenlenmiş veya düzenleme gerekli değil.'"));
		Return;
	EndIf;
	
	If DesignParameters.OneDocumentIsRequired Then
		
		DesignParameters.Insert("FillInByPicking", True);
		
		FormParameters = New Structure("FillingValues", DesignParameters);
		OpenForm("Document.WorkOutput.ObjectForm", FormParameters);
		
	Else
		
		Result = ProductionAccountingServerCall.FormDevelopmentOfSelectionStaff(DesignParameters);
		
		If Result.DocumentsCount > 0 Then
			OpenForm("Document.WorkOutput.Form.NewDocumentListForm",
				Result,,,,,);
		Else
			CommonClientServer.MessageToUser(
				NStr("vi = 'Không thể hoàn thành việc phát triển các đơn hàng đã chọn. Bắt buộc phải vào biểu mẫu ""Đăng ký"" và tạo chứng từ theo cách thủ công.';
					|ru = 'Не удалось оформить выработку по выбранным распоряжениям. Требуется перейти в форму ""К оформлению"" и создать документы вручную.';
					|en = 'Cannot register output by selected references. Go to the ""For registration"" form and create documents manually.'; fa = 'Cannot register output by selected references. Go to the ""For registration"" form and create documents manually.';
					|it = 'Non è stato possibile regolarizzare la produttività per le disposizioni selezionate. È necessario passare al form ""Da regolarizzare"" e creare i documenti manualmente.';
					|pl = 'Nie udało się sporządzić wytwarzanie wg wybranych zamówień. Trzeba przejść do formularza ""Do sporządzenia"" i utworzyć dokumenty ręcznie.';
					|tr = 'Seçili talimatlara göre işçilik ücretlendirmesi düzenlenemedi. ""Düzenlenecek"" formuna gidip belgeleri manuel olarak oluşturmanız gerekmektedir.'"));
		EndIf;
		
	EndIf;

EndProcedure

#Region RegistrationOfOperations

// The system generates alerts about the recording of production operations
//
// Parameters:
//  Department				 - CatalogRef.BusinessStructure	 - production unit
//  CallNotifyAboutChanges - Boolean									 - The truth is, if you want to call Povertymonitoring
//  ModifiedDocuments			 - Array, DocumentRef.ProductionOperation2_2	 - a list of the changed production operations.
//
Procedure NotifyAboutRecordingOfProductionOperations(Department, CallNotifyAboutChanges = True, ModifiedDocuments = Undefined) Export
	
	NotificationParameters = New Structure("Department, ModifiedDocuments", Department, ModifiedDocuments);
	
	Notify("Write_ProductionOperation2_2", NotificationParameters);
	
	If CallNotifyAboutChanges Then
		NotifyChanged(Type("DocumentRef.ProductionOperation2_2"));
		NotifyChanged(Type("InformationRegisterRecordKey.QueueOfProductionOperations"));
	EndIf; 
	
EndProcedure

// Notifies the user when the process of forming production operations is completed
//
// Parameters:
//  ResultOfFormation - See ProductionAccountingClientServer.ResultOfFormationOfProductionOfOperationsConstructor
//
Procedure NotifyUserAboutFormationOfProductionOperations(ResultOfFormation) Export
	
	If ResultOfFormation.ProcessedItemsCount > 0 Then
		
		QuantityCreated = ResultOfFormation.OperationsAreCreated.Count();
		QuantityUpdated = ResultOfFormation.UpdatedOperations.Count();
		
		If QuantityUpdated = 0 Then
			MessageText = StrTemplate(NStr("vi = 'Đã tạo %1 trong số %2 chứng từ';
											|ru = 'Сформировано %1 из %2 документов';
											|en = 'Generated %1 out of %2 documents'; fa = 'Generated %1 out of %2 documents';
											|it = 'Generated %1 out of %2 documents';
											|pl = 'Generated %1 out of %2 documents';
											|tr = '%2 belgeden %1 oluşturuldu'"),
				QuantityCreated,
				ResultOfFormation.TotalCount1);
			TitleText = NStr("vi = 'Giao dịch sản xuất đã lập';
							|ru = 'Производственные операции сформированы';
							|en = 'Routing operations are generated'; fa = 'Routing operations are generated';
							|it = 'Operazioni produttivi generati';
							|pl = 'Operacje produkcyjne zostały utworzone';
							|tr = 'Rota işlemleri oluşturuldu'");
		ElsIf QuantityCreated = 0 Then
			MessageText = StrTemplate(NStr("vi = 'Đã thay đổi %1 trong số %2 chứng từ';
											|ru = 'Изменено %1 из %2 документов';
											|en = 'Changed %1 out of %2 documents'; fa = 'Changed %1 out of %2 documents';
											|it = 'Changed %1 out of %2 documents';
											|pl = 'Changed %1 out of %2 documents';
											|tr = '%2 belgeden %1 değiştirildi'"),
				QuantityUpdated,
				ResultOfFormation.TotalCount1);
			TitleText = NStr("vi = 'Đã thay đổi giao dịch sản xuất';
							|ru = 'Производственные операции изменены';
							|en = 'Routing operations are changed'; fa = 'Routing operations are changed';
							|it = 'Routing operations are changed';
							|pl = 'Routing operations are changed';
							|tr = 'Rota işlemleri değiştirildi'")
		Else
			MessageText = StrTemplate(NStr("vi = 'Đã xử lý %1 trong số %2 chứng từ (đã tạo: %3, đã thay đổi: %4)';
											|ru = 'Обработано %1 из %2 документов (создано: %3, изменено: %4)';
											|en = 'Processed %1 of %2 documents (created: %3, changed: %4)'; fa = 'Processed %1 of %2 documents (created: %3, changed: %4)';
											|it = 'Processed %1 of %2 documents (created: %3, changed: %4)';
											|pl = 'Processed %1 of %2 documents (created: %3, changed: %4)';
											|tr = '%2 belgeden %1 adedi işlendi (oluşturulan: %3, değiştirilen: %4)'"),
				QuantityCreated+QuantityUpdated,
				ResultOfFormation.TotalCount1,
				QuantityCreated,
				QuantityUpdated);
			TitleText = NStr("vi = 'Đã xử lý giao dịch sản xuất';
							|ru = 'Производственные операции обработаны';
							|en = 'Routing operations are processed'; fa = 'Routing operations are processed';
							|it = 'Routing operations are processed';
							|pl = 'Routing operations are processed';
							|tr = 'Rota işlemleri işlendi'");
		EndIf;
		
	Else
		
		TitleText = NStr("vi = 'Giao dịch sản xuất không được lập';
						|ru = 'Производственные операции не сформированы';
						|en = 'Routing operations are not generated'; fa = 'Routing operations are not generated';
						|it = 'Operazioni produttivi non generati';
						|pl = 'Operacje produkcyjne nie zostały utworzone';
						|tr = 'Rota işlemleri oluşturulmadı'");
		MessageText = NStr("vi = 'Không có chứng từ nào được tạo';
							|ru = 'Не сформирован ни один документ';
							|en = 'No document is generated'; fa = 'No document is generated';
							|it = 'Non è stato generato alcun documento';
							|pl = 'Nie utworzono żadnego dokumentu';
							|tr = 'Herhangi bir belge oluşturulmadı'");
		
	EndIf;
	
	ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
	
EndProcedure

// Forms production operations
//
// Parameters:
//  Department			 - CatalogRef.BusinessStructure							 - production unit
//  OperationKeys			 - Array of InformationRegisterRecordKey.QueueOfProductionOperations - write key
//  AssignmentParameters		 - See ProductionAccountingClientServer.ParametersOfAssignmentOfProductionOperationConstructor
//  SetStatus_	- EnumRef.ProductionOperationStatuses				 - status of the new document
//
// Returns:
//  See ProductionAccountingClientServer.ResultOfFormationOfProductionOfOperationsConstructor
//
Function GenerateProductionOperations(Department, OperationKeys, AssignmentParameters, SetStatus_ = Undefined) Export
	
	Result = ProductionAccountingServerCall.GenerateProductionOperations(OperationKeys, AssignmentParameters, SetStatus_);
	
	If Not (Result.TotalCount1 = Result.ProcessedItemsCount)
		And Result.TotalCount1 = 1
		And Result.SpecialTerms.Count() = 0 Then
		
		ListOfFillingData = ProductionAccountingServerCall.DataForNewProductionOperations(
			OperationKeys, AssignmentParameters, SetStatus_, False);
		
		FillingValues = ListOfFillingData[0];
		
		If AssignmentParameters.Property("ActivityKinds") Then
			FillingValues.Insert("ActivityKinds", AssignmentParameters.ActivityKinds);
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("FillingValues", FillingValues);
		FormParameters.Insert("CheckWhenOpening", True);
		
		OpenForm("Document.ProductionOperation2_2.ObjectForm",
			FormParameters,
			ThisObject,
			,
			,
			,
			,
			FormWindowOpeningMode.Independent);
			
	Else
		
		NotifyUserAboutFormationOfProductionOperations(Result);
				
		ModifiedDocuments = New Array;
		CommonClientServer.SupplementArray(ModifiedDocuments, Result.OperationsAreCreated);
		CommonClientServer.SupplementArray(ModifiedDocuments, Result.UpdatedOperations);
		NotifyAboutRecordingOfProductionOperations(Department,, ModifiedDocuments);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the status for the list of operations
//
// Parameters:
//  References			 - Array								 - list of documents.
//  Status			 - String								 - new status.
//  Department	 - CatalogRef.BusinessStructure - production unit.
//
Procedure SetProductionOperationStatus(References, Status, Department) Export
	
	ClearMessages();
	
	PerformanceMonitorClient.StartTimeMeasurement(True, "Document.ProductionOperation2_2.SetStatus");
	
	StatusPresentation = "" + Status;
	
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(References, Status);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		Undefined,
		ProcessedItemsCount,
		References.Count(),
		StatusPresentation);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Department);
	
	CommonClient.NotifyObjectsChanged(References,NotificationParameter1);
	
EndProcedure

// Sets the delete mark for the list of operations
//
// Parameters:
//  References			 - Array								 - list of documents.
//  Department	 - CatalogRef.BusinessStructure - production unit.
//
Procedure CancelAssignmentOfProductionOperations(References, Department) Export
	ClearMessages();
	
	PerformanceMonitorClient.StartTimeMeasurement(True, "Document.ProductionOperation2_2.MarkToDelete");
	
	GeneralPurposeTMServerCall.SetDeletionMarkCompletionServer(References, True);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Department);
	
	CommonClient.NotifyObjectsChanged(References,NotificationParameter1);
	
EndProcedure

#EndRegion


#EndRegion

#Region Private


// Parameters for issuing confirmation when setting the Status of operation.
// 
// Parameters:
//  ObjectData - FormDataStructure
//  NewStatus - String,EnumRef.ProductionOperationStatuses
//  List - Boolean - The need to form a question in the plural
// 
// Returns:
//  Undefined,Structure - From:
// * NewStatus -  EnumRef.ProductionOperationStatuses,String
// * EventBeingConfirmed - String
// * QueryText - String
// * QuestionDialogMode - QuestionDialogMode
Function ConfirmationWhenSettingStatusOfOperation(ObjectData, NewStatus, List = False) Export
	
	Result = New Structure;
	Result.Insert("NewStatus", NewStatus);
	Result.Insert("EventBeingConfirmed", "");
	Result.Insert("QueryText", "");
	Result.Insert("QuestionDialogMode", QuestionDialogMode.YesNo);
	
	RefStatus = ProductionAccountingClientServer.StatusOfOperationLink(NewStatus);
	
	If RefStatus = PredefinedValue("Enum.ProductionOperationStatuses.IsSkipped")
		And ObjectData.Skippable Then
		
		Indicators = "FollowUp,QuantityUnderRevision,DefectiveGoodsCount,CountReal,QuantityIsReady";
		For Each Factor In StrSplit(Indicators, ",") Do
			Value = Undefined;
			If ObjectData.Property(Factor, Value) And Value > 0 Then
				Result.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CancellationOfIndicators();
				Result.QueryText = ?(List,
					NStr("vi = 'Khi thiết lập trạng thái ""Bỏ qua"", tất cả các chỉ số thực hiện tích lũy của giao dịch sẽ bị hủy. Tiếp tục?';
						|ru = 'При установке статуса ""Пропущена"" все накопленные показатели выполнения операций будут аннулированы. Продолжить?';
						|en = 'If you set the ""Skipped"" status, all accumulated performance indicators for the operations will be canceled. Continue?'; fa = 'If you set the ""Skipped"" status, all accumulated performance indicators for the operations will be canceled. Continue?';
						|it = 'При установке статуса ""Пропущена"" все накопленные показатели выполнения операций будут аннулированы. Продолжить?';
						|pl = 'If you set the ""Skipped"" status, all accumulated performance indicators for the operations will be canceled. Continue?';
						|tr = 'Durum ""Atlandı"" olarak yapılandırılırsa, işlemlere ilişkin birikmiş tüm göstergeler iptal edilecektir. Devam edilsin mi?'"),
					NStr("vi = 'Khi thiết lập trạng thái ""Bỏ qua"", tất cả các chỉ số thực hiện tích lũy của giao dịch sẽ bị hủy. Tiếp tục?';
						|ru = 'При установке статуса ""Пропущена"" все накопленные показатели выполнения операции будут аннулированы. Продолжить?';
						|en = 'If you set the ""Skipped"" status, all accumulated performance indicators for the operation will be canceled. Continue?'; fa = 'If you set the ""Skipped"" status, all accumulated performance indicators for the operation will be canceled. Continue?';
						|it = 'При установке статуса ""Пропущена"" все накопленные показатели выполнения операции будут аннулированы. Продолжить?';
						|pl = 'If you set the ""Skipped"" status, all accumulated performance indicators for the operation will be canceled. Continue?';
						|tr = 'Durum ""Atlandı"" olarak yapılandırılırsa, işleme ilişkin birikmiş tüm göstergeler iptal edilecektir. Devam edilsin mi?'"));
				Return Result;
			EndIf;
		EndDo;
		
	ElsIf RefStatus = PredefinedValue("Enum.ProductionOperationStatuses.NotExecuted")
		And ProductionProcessEditorClientServer.ThisOperationIsIndividual(ObjectData) Then
			
		Result.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CreatingIndividualOperation();
		Result.QueryText = ?(List,
			NStr("vi = 'Tạo các thao tác riêng biệt mới để thay thế những thao tác chưa thực hiện?';
				|ru = 'Создать новые индивидуальные операции взамен невыполненных?';
				|en = 'Create new individual operations to replace the uncompleted ones?'; fa = 'Create new individual operations to replace the uncompleted ones?';
				|it = 'Create new individual operations to replace the uncompleted ones?';
				|pl = 'Create new individual operations to replace the uncompleted ones?';
				|tr = 'Gerçekleştirilmeyenlerin yerine yeni özelleştirilmiş işlemler oluşturulsun mu?'"),
			NStr("vi = 'Tạo thao tác riêng biệt mới để thay thế thao tác chưa thực hiện?';
				|ru = 'Создать новую индивидуальную операцию взамен невыполненной?';
				|en = 'Create a new individual operation to replace the uncompleted one?'; fa = 'Create a new individual operation to replace the uncompleted one?';
				|it = 'Create a new individual operation to replace the uncompleted one?';
				|pl = 'Create a new individual operation to replace the uncompleted one?';
				|tr = 'Gerçekleştirilmeyenin yerine yeni özelleştirilmiş işlem oluşturulsun mu?'"));
		Result.QuestionDialogMode = QuestionDialogMode.YesNoCancel;
		Return Result;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Production Management: Contains procedures for production management.
// The module is part of the "Enterprise Management" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region OpeningForms

// Opens a production order with the product line highlighted
//
// Parameters:
//  OrderDocument		 - DocumentRef.ProductionOrder2_2 - production order
//  RowData - See ProductionManagementClientServer.OrderProductionStructure
//  Form		 - ClientApplicationForm						 - the form from which the transition is performed.
//
Procedure OpenProductionOrderLine(OrderDocument, RowData, Form) Export
	
	Parameters = New Structure("Key, RowSelected", OrderDocument, RowData);
	OpenForm("Document.ProductionOrder2_2.ObjectForm", Parameters, Form);
	
EndProcedure

// Opens the order queue
//
// Parameters:
//  FiltersStructure - Structure							 - set selections
//  CurrentRow	 - DocumentRef.ProductionOrder2_2 - production order
//  Form			 - ClientApplicationForm						 - the form from which the transition is performed.
//
Procedure OpenOrderQueue(FiltersStructure = Undefined, CurrentRow = Undefined, Form = Undefined) Export
	
	Parameters = New Structure;
	
	If FiltersStructure <> Undefined Then
		Parameters.Insert("FiltersStructure", FiltersStructure);
	EndIf;
	
	If CurrentRow <> Undefined Then
		Parameters.Insert("CurrentRow", CurrentRow);
	EndIf;
	
	OpenForm("Document.ProductionOrder2_2.Form.Queue", Parameters, Form);
	
EndProcedure

// Opens the edit form of a chain of stages
//
// Parameters:
//  ReferenceOrder		 - DocumentRef.ProductionOrder2_2 - production order
//  ProductionLot	 - CatalogRef.ProductionLots	 - Production batch
//  ManufacturedProduct			 - Array								 - array of structures that define the list of product shortages.
//  Form				 - ClientApplicationForm						 - form (owner)
//
Procedure OpenStageChainEditingForm(ReferenceOrder, ProductionLot, ManufacturedProduct = Undefined, Form = Undefined) Export
	
	Parameters = New Structure;
	
	Parameters.Insert("ReferenceOrder", ReferenceOrder);
	Parameters.Insert("ProductionLot", ProductionLot);
	Parameters.Insert("ManufacturedProduct", ManufacturedProduct);
	
	OpenForm("DataProcessor.EditProductionStageSequence.Form", Parameters, Form);
	
EndProcedure

// Opens the form for creating a new stage chain
//
// Parameters:
//  ReferenceOrder				 - DocumentRef.ProductionOrder2_2			 - production order.
//  ProductionProcessType - EnumRef.ProductionProcessTypes	 - type of production process.
//  Purpose					 - CatalogRef.Assignments						 - purpose of the order's products.
//  ManufacturedProduct					 - Array											 - array of structures that define the list of product shortages.
//  Form						 - ClientApplicationForm									 - form (owner).
//
Procedure OpenFormForCreatingNewStageChain(ReferenceOrder,
												ProductionProcessType,
												Purpose,
												ManufacturedProduct = Undefined,
												Form = Undefined) Export
	
	Parameters = New Structure;
	
	Parameters.Insert("ReferenceOrder", ReferenceOrder);
	Parameters.Insert("ProductionProcessType", ProductionProcessType);
	Parameters.Insert("Purpose", Purpose);
	Parameters.Insert("ManufacturedProduct", ManufacturedProduct);
	
	OpenForm("DataProcessor.EditProductionStageSequence.Form", Parameters, Form);
	
EndProcedure

// Opens the "performing operations" workspace with selection by production stage
//
// Parameters:
//  Stage	 - DocumentRef.ProductionStage2_2, Array	 - stage or list of stages
//  Form	 - ClientApplicationForm								 - the form from which the transition is performed.
//
Procedure OpenPerformingOperations(Stage, Form) Export
	
	ReferencesArrray = TMCommonUseClientServer.Array(Stage);
	
	SelectedDivision = Undefined;
	Departments = ProductionManagementServerCall.DivisionsPerformers(ReferencesArrray);
	For Each Ref In ReferencesArrray Do
		
		If SelectedDivision = Undefined Then
			SelectedDivision = Departments[Ref];
		EndIf;
		
		If SelectedDivision <> Departments[Ref] Then
			ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho các đối tượng được chọn!';
									|ru = 'Команда не может быть выполнена для выбранных объектов!';
									|en = 'Command cannot be executed for the selected objects.'; fa = 'Command cannot be executed for the selected objects.';
									|it = 'Il comando non può essere eseguito per oggetti selezionati!';
									|pl = 'Polecenie nie może być wykonane dla wybranych obiektów!';
									|tr = 'Seçili nesne için komut gerçekleştirilemez!'"));
			Return;
		EndIf;
		
	EndDo;
	
	DivisionParameters = ProductionServerCall.ProductionBusinessUnitDescription(SelectedDivision);
	
	If Not DivisionParameters.UseOperationManagement Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi, đơn vị không sử dụng quản lý vận hành!';
								|ru = 'Команда не может быть выполнена, в подразделении не используется пооперационное управление!';
								|en = 'Command cannot be executed, operation management is not used in the business unit.'; fa = 'Command cannot be executed, operation management is not used in the business unit.';
								|it = 'Il comando non può essere eseguito, nel reparto non viene applicata la gestione consecutiva delle operazioni!';
								|pl = 'Polecenie nie może być wykonane w dziale nie jest używane pooperacyjne zarządzanie!';
								|tr = 'Komut gerçekleştirilemez, departmanda üretim yürütme yönetimi kullanılmamaktadır!'"));
		Return;
	EndIf;
	
	ParametersStructure = New Structure("Department, FilterByStages", SelectedDivision, ReferencesArrray);
	
	If DivisionParameters.UseManufacturingExecutionSystem Then
		FormName = "DataProcessor.PerformOperationsMES.Form.Workplace";
	Else
		FormName = "DataProcessor.ExecutionOfOperations2_2.Form.Workplace";
	EndIf;
	
	OpenForm(FormName, ParametersStructure, Form);

EndProcedure

// Opens a simplified form for reflecting the completed production stage
//
// Parameters:
//  OrderObject  - FormDataStructure	 - The Production Order contains:
//                  * Ref                                     - DocumentRef.ProductionOrder2_2 -
//                  * AssignmentProducts                        - CatalogRef.Assignments -
//                  * ProductionLot                         - CatalogRef.ProductionLots -
//                  * MethodOfAllocatingFinishedProductCosts - EnumRef.MethodsOfCostAllocatingOnProductCosts -
//  Form       - ClientApplicationForm - the form from which the transition is performed.
//
Procedure OpenFormForDisplayingCompletedStageFromOrder(OrderObject, Form) Export
	
	ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
	EmptySpecification = PredefinedValue("Catalog.BillsOfMaterials.EmptyRef");
	
	HeaderAttributes = ProductionManagementServerCall.ValuesForFillingNewProductionStage(
		OrderObject.Ref,
		OrderObject.AssignmentProducts,
		OrderObject.ProductionLot,
		ProductionProcessType,
		EmptySpecification);
	
	Date = BegOfDay(CommonClient.SessionDate());
	Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed");
	
	HeaderAttributes.Insert("Status", Status);
	HeaderAttributes.Insert("MethodOfAllocatingFinishedProductCosts", OrderObject.MethodOfAllocatingFinishedProductCosts);

	HeaderAttributes.Insert("NotShipInInstallments",			True);
	HeaderAttributes.Insert("ConsumptionInOneDay",				True);
	HeaderAttributes.Insert("ProductionInOneDay",		True);
	HeaderAttributes.Insert("WorkPerformanceAsOneDay",	True);
	
	HeaderAttributes.Insert("Date",							Date);
	HeaderAttributes.Insert("ActualStageStart",		Date);
	HeaderAttributes.Insert("ActualStageEnd",	Date);
	HeaderAttributes.Insert("DateOfShipment",					Date);
	HeaderAttributes.Insert("DateOfMaterialWorkConsumption",					Date);
	HeaderAttributes.Insert("ProductionDate",				Date);
	HeaderAttributes.Insert("WorkExecutionDate",			Date);
	
	FillingValues = New Structure;
	FillingValues.Insert("HeaderAttributes", HeaderAttributes);
	
	Parameters = New Structure;
	Parameters.Insert("RecordOfPerformed", True);
	Parameters.Insert("FillingValues",    FillingValues);
	
	OpenForm("Document.ProductionStage2_2.ObjectForm", Parameters, Form);
	
EndProcedure

// Opens the shape selection stage of the consumer
//
// Parameters:
//  Object					 - DocumentObject.ProductionStage2_2	 - Stage
//  CurrentRow			 - Structure							 - data of the current row
//  Owner				 - ClientApplicationForm						 - the form or control in which the selection is made
//  CallbackDescription		 - CallbackDescription					 - contains a description of the procedure that will be called when the form is closed
//
Procedure OpenConsumerStageSelectionForm(Object, CurrentRow, Owner, CallbackDescription = Undefined) Export
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ReferenceOrder", Object.ReferenceOrder);

	FormParameters.Insert("Products", CurrentRow.Products);
	FormParameters.Insert("Characteristic", CurrentRow.Characteristic);
	FormParameters.Insert("Purpose", CurrentRow.Purpose);
	
	FormParameters.Insert("Recipient", CurrentRow.Recipient);
	
	FormParameters.Insert("Source", Object.Ref);
	
	OpenForm("AccumulationRegister.ProductionProcessSupply.Form.SelectionFormOfProductionStages",
		FormParameters,
		Owner,
		,
		,
		,
		CallbackDescription);
	
EndProcedure

// Opens a form that details the status of production operations in the production stage.
//
// Parameters:
//  Stage	  - DocumentRef.ProductionStage2_2 - stage.
//  State - EnumRef.StatesOfProductionStageOperations - status of operations.
//  Form	  - ClientApplicationForm - owner of the form to open.
//
Procedure DecodeStateOfStageOperations(Stage, State, Form) Export
	
	If Stage.IsEmpty() Then
		Return;
	EndIf;
	
	ReferencesArrray = TMCommonUseClientServer.Array(Stage);
	
	Departments = ProductionManagementServerCall.DivisionsPerformers(ReferencesArrray);
	Department = Departments[Stage];
	
	DivisionParameters = ProductionServerCall.ProductionBusinessUnitDescription(Department);
	
	If Not DivisionParameters.UseOperationManagement Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi, đơn vị không sử dụng quản lý vận hành!';
								|ru = 'Команда не может быть выполнена, в подразделении не используется пооперационное управление!';
								|en = 'Command cannot be executed, operation management is not used in the business unit.'; fa = 'Command cannot be executed, operation management is not used in the business unit.';
								|it = 'Il comando non può essere eseguito, nel reparto non viene applicata la gestione consecutiva delle operazioni!';
								|pl = 'Polecenie nie może być wykonane w dziale nie jest używane pooperacyjne zarządzanie!';
								|tr = 'Komut gerçekleştirilemez, departmanda üretim yürütme yönetimi kullanılmamaktadır!'"));
		Return;
	EndIf;
	
	If Not DivisionParameters.UseShiftTasks
		Or State = PredefinedValue("Enum.StatesOfProductionStageOperations.Completed2") Then
		
		FormParameters = New Structure("Department, FilterByStages", Department, ReferencesArrray);
		
		If DivisionParameters.UseManufacturingExecutionSystem Then
			FormName = "DataProcessor.PerformOperationsMES.Form.Workplace";
		Else
			FormName = "DataProcessor.ExecutionOfOperations2_2.Form.Workplace";
		EndIf;
		
		OpenForm(FormName, FormParameters, Form);
		
	Else
		
		If State = PredefinedValue("Enum.StatesOfProductionStageOperations.PendingCompletion") Then
			
			OpenForm(
				"Document.ShiftTask.ListForm",
				New Structure("FilterByStep", Stage),
				Form); 
			
		ElsIf State = PredefinedValue("Enum.StatesOfProductionStageOperations.PendingOperationAssignment") Then
			
			OpenForm(
				"DataProcessor.GenerateShiftTasks.Form",
				New Structure("FilterByStep", Stage),
				Form); 
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Opens the document form for operations with time measurement.
// 
// Parameters:
// 	Var_Key - DocumentRef.ProductionOperation2_2 -
Procedure OpenOperationDocumentForm(Var_Key) Export
	
	MeasurementUUID = PerformanceMonitorClient.TimeMeasurement("Document.ProductionOperation2_2.DocumentForm.OpeningForm",, False);
	
	FormParameters = New Structure();
	FormParameters.Insert("Key", Var_Key);
	
	OpenForm("Document.ProductionOperation2_2.Form.DocumentForm", FormParameters);
	
	PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID);
	
EndProcedure

#EndRegion

#Region UsersNotifications

// Notifies the user when the process of passing stages to execution is completed.
//
// Parameters:
//  Result	 - Structure			 - result of passing stages to execution
//  Source	 - UUID	 - ID of the form that initiated document creation.
//
Procedure NotifyUserWhenStepsAreReadyForExecution(Result, Source = Undefined) Export
	
	If Result.Count > 0 Then
		
		TextOfDocuments = TMCommonUseClientServer.InPlural(
				NStr("vi = 'chứng từ';
					|ru = 'документа';
					|en = 'document'; fa = 'document';
					|it = 'documento';
					|pl = 'dokumentu';
					|tr = 'belgeler'"), NStr("vi = 'chứng từ';
												|ru = 'документа';
												|en = 'document'; fa = 'document';
												|it = 'documento';
												|pl = 'dokumentu';
												|tr = 'belgeler'"), NStr("vi = 'chứng từ';
																		|ru = 'документов';
																		|en = 'documents'; fa = 'اسناد';
																		|it = 'documenti';
																		|pl = 'dokumentów';
																		|tr = 'belgeler'"), Result.Count);
		
		MessageText = NStr("vi = 'Đã gửi để thực hiện %Count% %TextOfDocuments%';
							|ru = 'Передано к выполнению %Count% %TextOfDocuments%';
							|en = 'Released %Count% %TextOfDocuments%'; fa = 'Released %Count% %TextOfDocuments%';
							|it = 'Consegnati per espletamento %Count%%TextOfDocuments%';
							|pl = 'Przekazano do wykonania %Count% %TextOfDocuments%';
							|tr = '%TextOfDocuments% %Count% uygulamaya aktarıldı'");
		MessageText = StrReplace(MessageText, "%Count%", Result.Count);
		MessageText = StrReplace(MessageText, "%TextOfDocuments%", TextOfDocuments);
		TitleText = NStr("vi = 'Các công đoạn sản xuất được chuyển sang thực hiện';
						|ru = 'Этапы производства переданы к выполнению';
						|en = 'Production stages are released'; fa = 'Production stages are released';
						|it = 'Le fasi della produzione sono consegnate per espletamento';
						|pl = 'Etapy produkcji zostały przekazane do realizacji';
						|tr = 'Üretim aşamaları uygulamaya aktarıldı'");
		
	Else
		
		MessageText = NStr("vi = 'Không có chứng từ nào được nộp để thực hiện';
							|ru = 'Ни один документ не передан к выполнению';
							|en = 'No document is released'; fa = 'No document is released';
							|it = 'Alcun documento è consegnato per espletamento';
							|pl = 'Żaden dokument nie został przekazany do wykonania';
							|tr = 'Herhangi bir belge uygulamaya aktarılmadı'");
		TitleText = NStr("vi = 'Các công đoạn sản xuất không được chuyển sang thực hiện';
						|ru = 'Этапы производства не переданы к выполнению';
						|en = 'Production stages are not released'; fa = 'Production stages are not released';
						|it = 'Le fasi della produzione non sono consegnate per espletamento';
						|pl = 'Etapy produkcji nie zostały przekazane do realizacji';
						|tr = 'Üretim aşamaları uygulamaya aktarılmadı'");
		
	EndIf;
	
	ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
	
EndProcedure

// Notifies the user when the process of creating production stages is complete.
//
// Parameters:
//  ResultOfFormation	 - Structure - the result of forming stages.
//  Source				 - UUID - ID of the form that initiated document creation.
//
Procedure NotifyUserAboutFormationOfProductionStages(ResultOfFormation, Source = Undefined) Export
	
	TitleText = NStr("vi = 'Kết quả của lập các kỳ sản xuất';
					|ru = 'Результат формирования этапов производства';
					|en = 'Production stage generation result'; fa = 'Production stage generation result';
					|it = 'Il risultato della generazione delle fasi di produzione';
					|pl = 'Wynik tworzenia etapów produkcji';
					|tr = 'Üretim aşamalarının düzenleme sonucu'");
	
	If ResultOfFormation.HasError Then
		AlertStatus = UserNotificationStatus.Important;
	Else
		AlertStatus = UserNotificationStatus.Information;
	EndIf;
	
	If ResultOfFormation.GeneratedDocuments_ > 0 Then
		
		TextOfDocuments = TMCommonUseClientServer.InPlural(
				NStr("vi = 'chứng từ';
					|ru = 'документа';
					|en = 'document'; fa = 'document';
					|it = 'documento';
					|pl = 'dokumentu';
					|tr = 'belgeler'"),
				NStr("vi = 'chứng từ';
					|ru = 'документа';
					|en = 'document'; fa = 'document';
					|it = 'documento';
					|pl = 'dokumentu';
					|tr = 'belgeler'"),
				NStr("vi = 'chứng từ';
					|ru = 'документов';
					|en = 'documents'; fa = 'اسناد';
					|it = 'documenti';
					|pl = 'dokumentów';
					|tr = 'belgeler'"),
				ResultOfFormation.GeneratedDocuments_);
		
		MessageText = NStr("vi = 'Lập %ProcessedItemsCount% %TextOfDocuments%';
							|ru = 'Сформировано %ProcessedItemsCount% %TextOfDocuments%';
							|en = 'Generated %ProcessedItemsCount% %TextOfDocuments%'; fa = 'Generated %ProcessedItemsCount% %TextOfDocuments%';
							|it = 'Generati %ProcessedItemsCount%%TextOfDocuments%';
							|pl = 'Utworzono %ProcessedItemsCount% %TextOfDocuments%';
							|tr = '%TextOfDocuments% %ProcessedItemsCount% oluşturuldu'");
		MessageText = StrReplace(
			MessageText,
			"%ProcessedItemsCount%",
			ResultOfFormation.GeneratedDocuments_);
		MessageText = StrReplace(MessageText, "%TextOfDocuments%", TextOfDocuments);
		
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32, AlertStatus);
		
	ElsIf Not ResultOfFormation.HasError Then
		
		MessageText = NStr("vi = 'Không có chứng từ nào được tạo';
							|ru = 'Не сформирован ни один документ';
							|en = 'No document is generated'; fa = 'No document is generated';
							|it = 'Non è stato generato alcun documento';
							|pl = 'Nie utworzono żadnego dokumentu';
							|tr = 'Herhangi bir belge oluşturulmadı'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32, AlertStatus);
		
	EndIf;
	
	If ResultOfFormation.HasError Then
		
		Ref = GetURL(ResultOfFormation.LinkError);
		
		MessageText = ResultOfFormation.ErrorText;
		ShowUserNotification(TitleText, Ref, MessageText, PictureLib.Error32, AlertStatus);
		
	EndIf;
	
	If ResultOfFormation.Property("References") And ValueIsFilled(ResultOfFormation.References) Then
		Notify("Write_ProductionStages", New Structure("References", ResultOfFormation.References));
	Else
		Notify("Write_ProductionStages");
	EndIf;
	
EndProcedure

// Notifies the user when the production schedule planning process is complete.
//
// Parameters:
//  Result	 - Structure - result of planning the production schedule.
//  Source	 - UUID	 - ID of the form that initiated document creation.
//
Procedure NotifyUserOfProductionSchedulePlanning(Result, Source = Undefined) Export
	
	If Result.HasErrors Then
		
		If Result.ProcessedItemsCount > 0 Then
			TitleText = NStr("vi = 'Đã lên lịch %ProcessedItemsCount% từ %TotalCount1% chứng từ';
							|ru = 'Запланировано %ProcessedItemsCount% из %TotalCount1% документов';
							|en = '%ProcessedItemsCount% documents planned out of %TotalCount1%'; fa = '%ProcessedItemsCount% documents planned out of %TotalCount1%';
							|it = 'Programmati %ProcessedItemsCount% di %TotalCount1% documenti';
							|pl = 'Zaplanowano %ProcessedItemsCount% z %TotalCount1% dokumentów';
							|tr = '%TotalCount1% belgesinden %ProcessedItemsCount% oluşturuldu'");
			TitleText = StrReplace(TitleText, "%ProcessedItemsCount%", Result.ProcessedItemsCount);
			TitleText = StrReplace(TitleText, "%TotalCount1%",        Result.TotalCount1);
		Else
			TitleText = NStr("vi = 'Lịch biểu sản xuất không theo kế hoạch';
							|ru = 'График производства не запланирован';
							|en = 'Production schedule is not created'; fa = 'Production schedule is not created';
							|it = 'Il piano di produzione non è programmato';
							|pl = 'Harmonogram produkcji nie został zaplanowany';
							|tr = 'Üretim programı planlanmadı'");
		EndIf;
		
		MessageText = StrTemplate(
			NStr("vi = 'Đã xảy ra lỗi trong khi lập kế hoạch đặt hàng  %1. Để biết thêm thông tin, hãy xem nơi làm việc ""Lập kế hoạch lịch trình của đơn đặt hàng"" (bấm để đi).';
				|ru = 'При планировании заказа %1 возникли ошибки. Подробнее см. в рабочем месте ""Планирование графика заказа"" (нажмите для перехода).';
				|en = 'Errors occurred when planning order %1. For more information, see the ""Order schedule planning"" workplace (click to go).'; fa = 'Errors occurred when planning order %1. For more information, see the ""Order schedule planning"" workplace (click to go).';
				|it = 'Nel corso della programmazione dell''ordine %1 sono stati rilevati gli errori. Per i dettagli vedere nella postazione di lavoro ""Programmazione del grafico dell''ordine"" (fare click per il passaggio).';
				|pl = 'Przy planowaniu zamówienia %1 wyniknęły błędy. Więcej informacji można znaleźć w miejscu pracy ""Planowanie harmonogramu zamówienia"" (kliknij aby przejść).';
				|tr = '%1 siparişi planlanırken hata oluştu. Daha fazla bilgi için bkz. çalışma alanında ""Sipariş Programı Planlaması"" (gitmek için tıklayın).'"),
			ProductionManagementServerCall.OrderPresentation(Result.ThisIsMistake, ""));
		
			
		AdditionalParameters = New Structure("ReferenceOrder", Result.ThisIsMistake);
		
		CallbackDescription = New CallbackDescription(
			"GoToOrderProductionSchedulePlanning", 
			ThisObject,
			AdditionalParameters);
	Else
		
		If Result.ProcessedItemsCount > 0 Then
			
			MessageText = NStr("vi = 'Đã lên lịch %ProcessedItemsCount% từ %TotalCount1% chứng từ';
								|ru = 'Запланировано %ProcessedItemsCount% из %TotalCount1% документов';
								|en = '%ProcessedItemsCount% documents planned out of %TotalCount1%'; fa = '%ProcessedItemsCount% documents planned out of %TotalCount1%';
								|it = 'Programmati %ProcessedItemsCount% di %TotalCount1% documenti';
								|pl = 'Zaplanowano %ProcessedItemsCount% z %TotalCount1% dokumentów';
								|tr = '%TotalCount1% belgesinden %ProcessedItemsCount% oluşturuldu'");
			MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", Result.ProcessedItemsCount);
			MessageText = StrReplace(MessageText, "%TotalCount1%",        Result.TotalCount1);
			TitleText = NStr("vi = 'Lịch biểu sản xuất theo kế hoạch';
							|ru = 'График производства запланирован';
							|en = 'Production schedule is created'; fa = 'برنامه تولید ایجاد شده است';
							|it = 'Il piano di produzione è programmato';
							|pl = 'Harmonogram produkcji został zaplanowany';
							|tr = 'Üretim programı planlandı'");
			
		Else
			
			MessageText = NStr("vi = 'Không có chứng từ theo kế hoạch';
								|ru = 'Не запланирован ни один документ';
								|en = 'No document is planned'; fa = 'No document is planned';
								|it = 'Non è stato programmato alcun documento';
								|pl = 'Nie został zaplanowany żaden dokument';
								|tr = 'Herhangi bir belge planlanmadı'");
			TitleText = NStr("vi = 'Lịch biểu sản xuất không theo kế hoạch';
							|ru = 'График производства не запланирован';
							|en = 'Production schedule is not created'; fa = 'Production schedule is not created';
							|it = 'Il piano di produzione non è programmato';
							|pl = 'Harmonogram produkcji nie został zaplanowany';
							|tr = 'Üretim programı planlanmadı'");
			
		EndIf;
		
		CallbackDescription = Undefined;
		
	EndIf;
	
	ShowUserNotification(TitleText, CallbackDescription, MessageText, PictureLib.Information32);
	
EndProcedure

// Notifies the user of the completion of the marking process for deleting stages to be completed.
//
// Parameters:
//  Result - Structure - the result of the operation.
//
Procedure NotifyUserAboutMarkToDeleteProductionStages(Result) Export
	
	LinkError = Undefined;
	
	If Result.QuantityProcessed > 0 Or Result.HasErrors Then
		
		TextOfDocuments = TMCommonUseClientServer.InPlural(
				NStr("vi = 'chứng từ';
					|ru = 'документа';
					|en = 'document'; fa = 'document';
					|it = 'documento';
					|pl = 'dokumentu';
					|tr = 'belgeler'"),
				NStr("vi = 'chứng từ';
					|ru = 'документа';
					|en = 'document'; fa = 'document';
					|it = 'documento';
					|pl = 'dokumentu';
					|tr = 'belgeler'"),
				NStr("vi = 'chứng từ';
					|ru = 'документов';
					|en = 'documents'; fa = 'اسناد';
					|it = 'documenti';
					|pl = 'dokumentów';
					|tr = 'belgeler'"),
				Result.QuantityProcessed);
	
		If Result.HasErrors Then
			TitleText = NStr("vi = 'Lỗi thiết lập đánh dấu trên các bước xóa!';
							|ru = 'Ошибка установки пометки на удаления этапов!';
							|en = 'An error occurred when marking stages for deletion.'; fa = 'An error occurred when marking stages for deletion.';
							|it = 'Errore dell''impostazione di contrassegno per eliminazione delle fasi!';
							|pl = 'Błąd ustawienia oznaczenia do usunięcia etapów!';
							|tr = 'Aşamaların silinmesi üzerine işaret yapılandırma hatası!'");
			TextPattern = NStr("vi = 'Đã xảy ra lỗi khi gắn cờ xóa chuỗi kỳ  %1! Đã đánh dấu để loại bỏ  %2%3.';
								|ru = 'При пометке на удаление цепочки этапов %1 возникла ошибка! Помечено на удаление %2 %3.';
								|en = 'An error occurred when marking stage chain %1 for deletion. Marked for deletion %2 %3.'; fa = 'An error occurred when marking stage chain %1 for deletion. Marked for deletion %2 %3.';
								|it = 'Nel corso dell''impostazione di contrassegno per eliminazione del percorso fasi %1 si è verificato un errore! Contrassegnati per eliminazione %2 %3.';
								|pl = 'Podczas oznaczenia na usunięcie łańcucha etapów %1 wystąpił błąd! Oznaczono do usunięcia %2 %3.';
								|tr = '%1 aşamasının zinciri silinmek üzere işaretlenirken hata oluştu! %3 %2 silinmek üzere işaretlendi.'");
			MessageText = StrTemplate(TextPattern,Result.LinkError,Format(Result.QuantityProcessed,"NZ=; NG="),TextOfDocuments);
		Else
			TitleText = NStr("vi = 'Các công đoạn sản xuất được đánh dấu để xóa.';
							|ru = 'Этапы производства помечены на удаление.';
							|en = 'Production stages are marked for deletion.'; fa = 'Production stages are marked for deletion.';
							|it = 'Le fasi della produzione contrassegnate per eliminazione.';
							|pl = 'Etapy produkcji zostały oznaczone do usunięcia.';
							|tr = 'Üretim aşamaları silinmek üzere işaretlendi.'");
			TextPattern = NStr("vi = 'Đã đánh dấu để xóa  %1 %2';
								|ru = 'Помечено на удаление %1 %2';
								|en = 'Marked for deletion %1 %2'; fa = 'Marked for deletion %1 %2';
								|it = 'Contrassegnate per eliminazione %1 %2';
								|pl = 'Oznaczono do usunięcia %1 %2';
								|tr = '%2 %1 silinmek üzere işaretlendi'");
			MessageText = StrTemplate(TextPattern,Format(Result.QuantityProcessed,"NZ=; NG="),TextOfDocuments);
		EndIf;
		
		If Result.HasErrors Then 
			LinkError = GetURL(Result.LinkError);
		EndIf;
		
	Else
		
		MessageText = NStr("vi = 'Không có chứng từ được đánh dấu để xóa';
							|ru = 'Ни один документ не помечен на удаление';
							|en = 'No document is marked for deletion'; fa = 'No document is marked for deletion';
							|it = 'Alcun documento è contrassegnato per eliminazione';
							|pl = 'Żaden dokument nie jest oznaczony do usunięcia';
							|tr = 'Silinmek üzere herhangi bir belge işaretlenmedi'");
		TitleText = NStr("vi = 'Không thể đánh dấu các công đoạn sản xuất để xóa';
						|ru = 'Не удалось пометить на удаление этапы производства';
						|en = 'Cannot mark production stages for deletion'; fa = 'Cannot mark production stages for deletion';
						|it = 'Non è stato possibile contrassegnare per eliminazione le fase della produzione';
						|pl = 'Nie udało się oznaczyć do usunięcia etapy produkcji';
						|tr = 'Üretim aşamalarını silinmek üzere işaretlenemedi'");
		
	EndIf;
	
	ShowUserNotification(TitleText, LinkError, MessageText, PictureLib.Information32);	
	
EndProcedure

// Notifies the user about a change in the production order.
//
// Parameters:
//  Result	 - Structure				 - result of full calculation (or cancellation of calculation) of the order structure
//  Source	 - UUID	 - ID of the form that initiated document creation.
//
Procedure NotifyUserAboutChangesInProductionOrders(Result, Source = Undefined) Export
	
	ProcessedItemsCount = Result.ProcessedDocuments.Count();
	
	If Result.TotalDocuments > ProcessedItemsCount Then
		
		TitleText = StrTemplate(NStr("vi = 'Thay đổi (%1 trong số %2)';
									|ru = 'Изменение (%1 из %2)';
									|en = 'Change (%1 out of %2)'; fa = 'Change (%1 out of %2)';
									|it = 'Modifica (%1 di %2)';
									|pl = 'Zmiana (%1 z %2)';
									|tr = 'Değişim (%2 üzerinden %1)'"), Format(ProcessedItemsCount,"NZ=; NG="), Format(Result.TotalDocuments,"NZ=; NG="));
		MessageText = NStr("vi = 'Quản lý trình tự đơn hàng sản xuất';
							|ru = 'Управление очередью заказов на производство';
							|en = 'Management of production order queue'; fa = 'مدیریت صف سفارش‌های تولید';
							|it = 'Gestione della priorità degli ordini alla produzione';
							|pl = 'Zarządzanie kolejką zamówień na produkcję';
							|tr = 'Üretim emri kuyruğu yönetimi'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Attention32);
		
		
	Else
	
		TitleText = StrTemplate(NStr("vi = 'Thay đổi (%1)';
									|ru = 'Изменение (%1)';
									|en = 'Change (%1)'; fa = 'Change (%1)';
									|it = 'Modifica (%1)';
									|pl = 'Zmiana (%1)';
									|tr = 'Değişim (%1)'"), Format(ProcessedItemsCount,"NZ=; NG="));
		MessageText = NStr("vi = 'Quản lý trình tự đơn hàng sản xuất';
							|ru = 'Управление очередью заказов на производство';
							|en = 'Management of production order queue'; fa = 'مدیریت صف سفارش‌های تولید';
							|it = 'Gestione della priorità degli ordini alla produzione';
							|pl = 'Zarządzanie kolejką zamówień na produkcję';
							|tr = 'Üretim emri kuyruğu yönetimi'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf;
	
	CommonClient.NotifyObjectsChanged(Result.ProcessedDocuments, New Structure("ProductionOrders", Result.ProcessedDocuments));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region EditingProductionStage

#Region ManufacturedProducts

// Event at the beginning of editing the output table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form being processed.
//  CurrentData - FormDataCollectionItem - current data.
//  TSName         - String - name of the table part.
//  NewRow   - Boolean - indicates a new line.
//  Copy   - Boolean - the copy flag.
//
Procedure OutputProductsOfStageAtBeginningOfEditing(Form, CurrentData, TSName, NewRow, Copy) Export
	
	Items = Form.Items;
	
	If NewRow Then
		
		CurrentData.RowCode = 0;
		CurrentData.KeyProducts = Undefined;
		
		WarehousesClientServer.FillDefaultWarehouse(
				Form.UseSeveralWarehouses, 
				Form.DefaultWarehouse, 
				CurrentData,
				"Recipient");
		
	EndIf;
	
	FillReleaseDirectionSelectionList(CurrentData, TSName, Form);
	
	If NewRow And Not Copy Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(Form, CurrentData, "Object." + TSName);
	EndIf;
	
	If NewRow And Not ValueIsFilled(CurrentData.DirectionOfProductionIssue) Then
		CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Recipient) Then
		If CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit")
			Or CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
			CurrentData.Recipient = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		Else
			CurrentData.Recipient = PredefinedValue("Catalog.Warehouses.EmptyRef");
		EndIf;
	EndIf;
	
	RestrictionOfRecipientType(Items[TSName + "Recipient"], CurrentData.DirectionOfProductionIssue);
	
EndProcedure

// Event when the output Direction field is changed.
//
// Parameters:
//  CurrentData        - FormDataCollectionItem - current data.
//  TSName                - String - name of the table part.
//  Form                - ClientApplicationForm - the form being processed.
//  Object               - FormDataStructure - The object being processed.
//  CachedValues - Structure - a form module variable that stores cached values.
//
Procedure OutputProductsOfStageOfDirectionOfReleaseWhenChanging(CurrentData, TSName, Form, Object, CachedValues) Export
	
	Items = Form.Items;
	
	If Not ValueIsFilled(CurrentData.DirectionOfProductionIssue) Then
		CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
	EndIf;
	
	CurrentData.ToExpenseAs = (CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"));
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(Form, CurrentData, "Object." + TSName);
	
	RestrictionOfRecipientType(Items[TSName + "Recipient"], CurrentData.DirectionOfProductionIssue);
	CurrentData.Recipient = Items[TSName + "Recipient"].TypeRestriction.AdjustValue(CurrentData.Recipient);
	
	If CurrentData.DirectionOfProductionIssue <> PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse") Then
		CurrentData.ProcessByBOM = False;
		CurrentData.BillOfMaterials = Undefined;
	EndIf;
	
	StructureOfActions = New Structure;
	
	PurposeOfTollRelease =
		?(CurrentData.ToExpenseAs, Undefined, Form.PurposeOfTollRelease);
	
	StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
	
	
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(Form, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	OutputProductsOfRecipientStageWhenChanging(CurrentData, TSName, Form, Object, CachedValues);
	
EndProcedure

Procedure OutputProductsOfRecipientStageWhenChanging(CurrentData, TSName, Form, Object, CachedValues) Export
	
	SeriesSpecificationParameters = Form[Form.StageEditingParameters.PropsNameParametersForSpecifyingSeries];
	
	If CurrentData.Recipient = Undefined Then
		CurrentData.Recipient = PredefinedValue("Catalog.Warehouses.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus", 
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Recipient, SeriesSpecificationParameters[TSName]));
		
	StructureOfActions.Insert("FillInShopPantryAttribute", New Structure("WarehouseFieldName", "Recipient"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

// Fills in the release direction selection list.
//
// Parameters:
//  CurrentData - FormDataCollectionItem - current data.
//  TSName         - String - name of the table part.
//  Form         - ClientApplicationForm - the form being processed.
//
// Returns:
//	ValueList
// 	
Function FillReleaseDirectionSelectionList(CurrentData, TSName, Form) Export

	Items = Form.Items;
	
	ItemSelectionList = Items[TSName + "DirectionOfProductionIssue"].ChoiceList;
	ItemSelectionList.Clear();
	
	For Each Item In ProductionManagementClientServer.ReleaseDirectionSelectionList(CurrentData, Form) Do
		ItemSelectionList.Add(Item.Value, Item.Presentation);
	EndDo;	

	Return ItemSelectionList;
	
EndFunction

#EndRegion

Procedure ItemsOfAmountStageWhenChanged(CurrentData, CachedValues) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

Procedure ProductsOfStagePriceWhenChanging(CurrentData, CachedValues) Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#Region UnusedMaterials

// Event at the beginning of editing the material Economy table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form being processed.
//  Object        - FormDataStructure - The object being processed.
//  CurrentData - FormDataCollectionItem - current data.
//  NewRow   - Boolean - indicates a new line.
//  Copy   - Boolean - the copy flag.
//
Procedure UnusedMaterialsOnStartEdit(Form, Object, CurrentData, NewRow, Copy) Export
	
	Items = Form.Items;
	
	If NewRow Then
		
		CurrentData.RowCode = 0;
		
		WarehousesClientServer.FillDefaultWarehouse(
				Form.UseSeveralWarehouses, 
				Form.DefaultWarehouse, 
				CurrentData,
				"Recipient");
		
		If Object.ConsumptionInOneDay And Object.DateOfMaterialWorkConsumption <> '000101010000' Then
			CurrentData.DateOfTransaction = Object.DateOfMaterialWorkConsumption;
		EndIf;
		
	EndIf;
	
	HowToFillActionSelectionList(CurrentData, Form);
	
	If NewRow And Not Copy Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(Form, CurrentData, "Object.UnusedMaterials");
	EndIf;
	
	If NewRow And Not Copy Then
		CurrentData.Actions = PredefinedValue("Enum.BusinessTransactions.ReturnFromProduction");
	EndIf;
	
	RestrictionOfRecipientType(Items.UnusedMaterialsRecipient, CurrentData.Actions);
	
EndProcedure

// Event when the action material Economy field changes.
//
// Parameters:
//  CurrentData        - FormDataCollectionItem - current data.
//  Form                - ClientApplicationForm - the form being processed.
//  Object               - FormDataStructure - The object being processed.
//  CachedValues - Structure - a form module variable that stores cached values.
//
Procedure SavingMaterialsOfStageActionWhenChanging(CurrentData, Form, Object, CachedValues) Export
	
	Items = Form.Items;
	
	If Not ValueIsFilled(CurrentData.Actions) Then
		CurrentData.Actions = PredefinedValue("Enum.BusinessTransactions.ReturnFromProduction");
	EndIf;
	
	CurrentData.ToExpenseAs = (CurrentData.Actions = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"));
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(Form, CurrentData, "Object.UnusedMaterials");
	
	If CurrentData.ToExpenseAs Then
		CurrentData.Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
	EndIf;
	
	RestrictionOfRecipientType(Items.UnusedMaterialsRecipient, CurrentData.Actions);
	
	CurrentData.Recipient = Items.UnusedMaterialsRecipient.TypeRestriction.AdjustValue(
												CurrentData.Recipient);
		
	RecipientOnChange(CurrentData, "UnusedMaterials", Form, Object, CachedValues);
	
EndProcedure

Procedure SavingMaterialsFillInFeatureSeparately(CurrentData, SupplyWithMaterialsAndWorks) Export
	
	Filter = New Structure;
	Filter.Insert("Products", CurrentData.Products);
	Filter.Insert("Characteristic", CurrentData.Characteristic);
	Filter.Insert("WithAssignment", True);
	
	If SupplyWithMaterialsAndWorks.FindRows(Filter).UBound() = -1 Then
		CurrentData.Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
	EndIf;
	
EndProcedure

Function HowToFillActionSelectionList(CurrentData, Form)

	Items = Form.Items;
	
	ItemSelectionList = Items.UnusedMaterialsActions.ChoiceList;
	ItemSelectionList.Clear();
	
	ItemSelectionList.Add(PredefinedValue("Enum.BusinessTransactions.ReturnFromProduction"),
									NStr("vi = 'Chuyển đến kho';
										|ru = 'Передать на склад';
										|en = 'Transfer to warehouse'; fa = 'انتقال به انبار';
										|it = 'Trasferire al magazzino';
										|pl = 'Przekaż do magazynu';
										|tr = 'Ambara transfer et'"));
	
	If Form.UseWriteOffForExpenses Then
		ItemSelectionList.Add(PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
									NStr("vi = 'Ghi giảm vào chi phí';
										|ru = 'Списать на расходы';
										|en = 'Expense as'; fa = 'هزینه به عنوان';
										|it = 'Stornare sulle spese';
										|pl = 'Spisać w koszty';
										|tr = 'Gider olarak kaydet'"));
	EndIf;
	
	Return ItemSelectionList;
	
EndFunction

#EndRegion

#Region MaterialSupply

// Provision of materials and works of the stage at the beginning of editing.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CurrentData - FormDataCollectionItem
//  NewRow - Boolean
//  Copy - Boolean
//
Procedure ProvisionOfMaterialsAndWorksOfStageAtBeginningOfEditing(Form, CurrentData, NewRow, Copy) Export
	
	If NewRow Then
		
		CurrentData.RowCode = 0;
		CurrentData.KeyProducts = Undefined;
		
		WarehousesClientServer.FillDefaultWarehouse(
				Form.UseSeveralWarehouses,
				Form.DefaultWarehouse,
				CurrentData);
		
	EndIf;
	
EndProcedure

Function ProvisionOfMaterialsAndWorksForWarehouseStageInCaseOfChanges(Form, CurrentData, SeriesSpecificationParameters, CachedValues) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters));
		
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		New Structure("Form", Form));
		
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	Return StructureOfActions;
	
EndFunction

#EndRegion

#Region Other

// Goes to the line with auto-selection that you want to specify.
//
// Parameters:
//  Object             - FormDataStructure - The object being processed.
//  Form              - ClientApplicationForm - the form being processed.
//  TSName              - String - name of the table part.
//  CurrentRowNumber1 - Number - room of stork.
//  Direction        - Number - direction.
//
Procedure GoToAutoSelectLineThatYouWantToSpecify(Object, Form, TSName, CurrentRowNumber1, Direction) Export
	
	If Object[TSName].Count() = 0 Then
		Return;
	EndIf;
	
	Items = Form.Items;
	
	If Direction = 1 Then
		For Each String In Object[TSName] Do
			
			If String.Products.IsEmpty()
					Or String.Characteristic.IsEmpty() And String.ItemVariantsAreUsed Then
				
				If String.LineNumber > CurrentRowNumber1 Then
					
					Table = Items[TSName];//FormTable
					Table.CurrentRow = String.GetID();
					
					Return;
					
				EndIf;
				
			EndIf;
			
		EndDo;
	Else
		
		Cnt = Object[TSName].Count() - 1;
		
		While Cnt >= 0 Do
			
			String = Object[TSName][Cnt];
			
			If String.Products.IsEmpty()
					Or String.Characteristic.IsEmpty() And String.ItemVariantsAreUsed Then
				
				If String.LineNumber < CurrentRowNumber1 Then
					
					Table = Items[TSName];//FormTable
					Table.CurrentRow = String.GetID();
					
					Return;
					
				EndIf;
				
			EndIf;
			
			Cnt = Cnt - 1;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure RestrictionOfRecipientType(Item, BusinessOperation)
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		
		RestrictionOfRecipientType = New TypeDescription("CatalogRef.BusinessStructure");
		
	Else
		
		RestrictionOfRecipientType = New TypeDescription("CatalogRef.Warehouses");
		
	EndIf;
	
	Item.TypeRestriction = RestrictionOfRecipientType;

EndProcedure

Procedure RecipientOnChange(LineOfATabularSection, TSName, Form, Object, CachedValues) Export
	
	SeriesSpecificationParameters = Form[Form.StageEditingParameters.PropsNameParametersForSpecifyingSeries];
	
	StructureOfActions = New Structure;
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", LineOfATabularSection.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	StructureOfActions.Insert("FillInShopPantryAttribute", New Structure("WarehouseFieldName", "Recipient"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ProductionManagementClientServer.AddQualityControlActionsToStructure(TSName, StructureOfActions, Form.CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

Procedure GoToOrderProductionSchedulePlanning(AdditionalParameters) Export
	
	FormName = "DataProcessor.ProductionSchedulePlanning2_2.Form.CreatingProductionOrderSchedule";
	
	OpenForm(FormName, AdditionalParameters,, AdditionalParameters.ReferenceOrder);
	
EndProcedure

// Checks and deletes incomplete stage chains from the list.
//
// Parameters:
//  List - FormTable - the list being processed.
//
Procedure CheckRemoveIncompleteStageChainsFromList(List) Export
	
	SelectedRows = List.SelectedRows;
	
	ArrayOfStages = New Array;
	RowsMap = New Map;
	
	For Each CurrentRow In SelectedRows Do
		RowData = List.RowData(CurrentRow);//DocumentRef - Data type formelementcollection
		Ref = RowData.Ref; 
		If TypeOf(Ref) = Type("DocumentRef.ProductionStage2_2") Then
			ArrayOfStages.Add(Ref);
			RowsMap.Insert(Ref, CurrentRow);
		EndIf;
	EndDo;
	
	ArrayOfStages = ProductionManagementServerCall.ListOfProductionStepsAvailableForDeletion(ArrayOfStages);
	
	If RowsMap.Count() <> ArrayOfStages.Count() Then
	
		For Each KeyAndValue In RowsMap Do
			If ArrayOfStages.Find(KeyAndValue.Key) = Undefined Then
				SelectedRows.Delete(SelectedRows.Find(KeyAndValue.Value));
			EndIf;
		EndDo;
		
		MessageText = NStr("vi = 'Việc xóa một phần các kỳ trong quy trình sản xuất nhiều kỳ đều bị cấm, sử dụng nơi làm việc ""Cấu trúc của một đơn đặt hàng sản xuất""';
							|ru = 'Частичное удаление этапов при многоэтапном производственном процессе запрещено, воспользуйтесь рабочим местом ""Структура заказа на производство""';
							|en = 'Partial deletion of stages in a multi-stage production process is prohibited. Use the ""Production order structure"" workplace'; fa = 'Partial deletion of stages in a multi-stage production process is prohibited. Use the ""Production order structure"" workplace';
							|it = 'La cancellazione parziale delle fasi con il processo produttivo multifase è proibita, usare la postazione di lavoro ""Struttura dell''ordine di produzione""';
							|pl = 'Częściowe usunięcie etapów w wieloetapowym procesie produkcji jest zabronione, skorzystaj z miejsca pracy ""Struktura zlecenia produkcyjnego""';
							|tr = 'Çok aşamalı üretim sürecinde aşamaların kısmi olarak silinmesi yasaktır, ""Üretim Emri Yapısı"" çalışma alanını kullanın'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

// Searches for the production stage by the transmitted barcode.
//
// Parameters:
//  Barcode - String - barcode.
// 
// Returns:
//  DocumentRef.ProductionStage2_2, Undefined - reference to the found stage, Undefined if the value is not found.
//
Function LinkToProductionStageByBarcode(Barcode) Export
	
	Result = Undefined;
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionStage2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.ProductionLots.EmptyRef"));
	ReferencesArrray = BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
	If ReferencesArrray.Count() > 0 Then
		If TypeOf(ReferencesArrray[0]) = Type("DocumentRef.ProductionStage2_2") Then
			Result = ReferencesArrray[0];
		ElsIf TypeOf(ReferencesArrray[0]) = Type("CatalogRef.ProductionLots") Then
			Result = ProductionManagementServerCall.StepOnBarcodeOfProductionBatch(ReferencesArrray[0]);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Other

// The procedure shifts the newly edited row in the collection 
// so that the rows in the collection remain ordered.
//
// Parameters:
//	RowsCollection - FormDataCollection - collection of strings.
//	OrderField - String - the name of the field of the collection item 
//		to be sorted by.
//	CurrentRow - FormDataCollectionItem - edited collection line.
//
Procedure RestoreCollectionRowOrderAfterEditing(RowsCollection, OrderField, CurrentRow) Export
	
	If RowsCollection.Count() < 2 Then
		Return;
	EndIf;
	
	If TypeOf(CurrentRow[OrderField]) <> Type("Date") 
		And Not ValueIsFilled(CurrentRow[OrderField]) Then
		Return;
	EndIf;
	
	SourceIndex = RowsCollection.IndexOf(CurrentRow);
	IndexResult = SourceIndex;
	
	// Select the direction in which you want to move.
	Direction = 0;
	If SourceIndex = 0 Then
		// Down
		Direction = 1;
	EndIf;
	If SourceIndex = RowsCollection.Count() - 1 Then
		// Up
		Direction = -1;
	EndIf;
	
	If Direction = 0 Then
		If RowsCollection[SourceIndex][OrderField] > RowsCollection[IndexResult + 1][OrderField] Then
			// Down
			Direction = 1;
		EndIf;
		If RowsCollection[SourceIndex][OrderField] < RowsCollection[IndexResult - 1][OrderField] Then
			// Up
			Direction = -1;
		EndIf;
	EndIf;
	
	If Direction = 0 Then
		Return;
	EndIf;
	
	If Direction = 1 Then
		// You need to shift until the value in the current row is greater than in the next one.
		While IndexResult < RowsCollection.Count() - 1 
			And RowsCollection[SourceIndex][OrderField] > RowsCollection[IndexResult + 1][OrderField] Do
			IndexResult = IndexResult + 1;
		EndDo;
	Else
		// You need to shift until the value in the current row is less than in the previous one.
		While IndexResult > 0 
			And RowsCollection[SourceIndex][OrderField] < RowsCollection[IndexResult - 1][OrderField] Do
			IndexResult = IndexResult - 1;
		EndDo;
	EndIf;
	
	RowsCollection.Move(SourceIndex, IndexResult - SourceIndex);
	
EndProcedure

#EndRegion

#EndRegion
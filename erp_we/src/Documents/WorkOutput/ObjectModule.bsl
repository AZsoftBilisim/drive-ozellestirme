#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillDefaultAttributes();
	
	If TypeOf(FillingData) = Type("Structure") Or TypeOf(FillingData) = Type("QueryResultSelection") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	If ValueIsFilled(ThisObject.Department) Then
		FillPropertyValues(ThisObject,
		Common.ObjectAttributesValues(ThisObject.Department, "UseLPR,UseTariffRates,UseHoursWorked"));
	EndIf;
	
	If WorkOrderKind = Enums.TeamWorkOrderKinds.TeamByOrder21
		Or WorkOrderKind = Enums.TeamWorkOrderKinds.TeamWithoutOrder21
		Or WorkOrderKind = Enums.TeamWorkOrderKinds.Repair Then
		AutoAllocation = Common.ObjectAttributeValue(ThisObject.Team, "AllocateByLPR");
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("IncludeInPeriodOfWork") And FillingData.IncludeInPeriodOfWork
			And ValueIsFilled(FillingData.EndOfPeriod) Then
			Date = FillingData.EndOfPeriod;
		EndIf;
		
		If FillingData.Property("IncludeInPeriodOfWork") And Not FillingData.IncludeInPeriodOfWork Then
			Month = BegOfMonth(CurrentSessionDate());
		EndIf;
		
		If FillingData.Property("FillInByPicking") Then
			
			Documents.WorkOutput.FillOutTypesOfWorkOnBalances(ThisObject, FillingData);
			
			If WorkOrderKind <> Enums.TeamWorkOrderKinds.Personal Then
				Documents.WorkOutput.FillWorkers(ThisObject);
			EndIf;
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	If Not ValueIsFilled(Month) Then
		Month = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	DateToCheck = Date;
	If Not ValueIsFilled(DateToCheck) Then
		DateToCheck = ?(ValueIsFilled(Month), Month, CurrentSessionDate());
	EndIf;
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(DateToCheck);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	Var ArrayOfUnusedProps;
	
	NotCheckedAttributeArray = New Array;
	
	Documents.WorkOutput.NamesOfPropsByTypeOfOutfit(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	If AccountingForLaborCostsByEmployees And ArrayOfOperationDetails.Find("ActivityKinds.Employee") <> Undefined
		And ArrayOfOperationDetails.Find("ActivityKinds.Employee_") <> Undefined Then
		// If backflushed production with physical. if the person corrects the document with the employee, then the verification of filling in the Employee field is disabled
		ArrayOfOperationDetails.Delete(ArrayOfOperationDetails.Find("ActivityKinds.Employee"));
	ElsIf AccountingForLaborCostsByEmployees And ArrayOfOperationDetails.Find("ActivityKinds.Employee") <> Undefined Then
		ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	ArrayOfUnusedProps = CommonClientServer.ArraysDifference(ArrayOfAllProps, ArrayOfOperationDetails);
	
	For Each Attribute In ArrayOfUnusedProps Do
		NotCheckedAttributeArray.Add(Attribute);
	EndDo;
	
	MessageTemplate = NStr("vi = 'Ngày thực hiện công việc trong dòng %1 của danh sách ""Công việc được thực hiện"" không tương ứng với tháng chứng từ';
							|ru = 'Дата выполнения работ в строке %1 списка ""Выполненные работы"" не соответствует месяцу документа';
							|en = 'The work completion date in line %1 of the ""Performed works"" list does not correspond to the document month'; fa = 'The work completion date in line %1 of the ""Performed works"" list does not correspond to the document month';
							|it = 'Дата выполнения работ в строке %1 списка ""Выполненные работы"" не соответствует месяцу документа';
							|pl = 'The work completion date in line %1 of the ""Performed works"" list does not correspond to the document month';
							|tr = '""Tamamlanan İşler"" listesinin %1 satırındaki işin tamamlanma tarihi, belgenin ayına karşılık gelmiyor'");
	
	For Each String In ActivityKinds Do
		If String.WorkExecutionDate < Month Or String.WorkExecutionDate > EndOfMonth(Month) Then
			
			MessageText = StrTemplate(MessageTemplate , String(String.LineNumber));
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				CommonClientServer.PathToTabularSection("ActivityKinds", String.LineNumber, "WorkExecutionDate"),
				"Object",
				Cancel)
			
		EndIf;
	EndDo;
	
	If WorkOrderKind = Enums.TeamWorkOrderKinds.TeamKind Or AutoAllocation Then
		If ActivityKinds.Total("Sum") <> Employees.Total("Sum") Then
			
			MessageText = NStr("vi = 'Số lượng công việc không được phân bổ giữa những người tham gia trong lữ đoàn. Cần phải phân bổ số tiền trên tab ""Nhân viên""';
								|ru = 'Сумма работ не распределена по участникам бригады. Требуется распределить сумму на закладке ""Работники""';
								|en = 'The amount for the works is not allocated by the work team members. Allocate the amount on the ""Employees"" tab'; fa = 'The amount for the works is not allocated by the work team members. Allocate the amount on the ""Employees"" tab';
								|it = 'L''ammontare di lavoro non è distribuito tra i membri della squadra. È necessario distribuire l''importo nella scheda ""Dipendenti""';
								|pl = 'Wartość prac nie jest podzielona według uczestników brygady. Jest wymagane przydzielenie wartości na wkładcę ""Работники""';
								|tr = 'İş miktarı çalışma ekibi üyelerine dağıtılmadı. ""Çalışanlar"" sekmesinde tutar dağıtmanız gerekmektedir.'");
			
			CommonClientServer.MessageToUser(
				MessageText,
				ThisObject,
				"Employees",
				,
				Cancel);
			
		EndIf;
	EndIf;
	
	If AccountingForLaborCostsByEmployees Then
		//++WE
		If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
			
			MessageParameters = New Structure("ObjectName, FieldNameEmployee");
			MessageParameters.FieldNameEmployee = "Employee";
			
			AuditedEmployees = New Array;
			If ArrayOfOperationDetails.Find("Employees.Employee") <> Undefined Then
				AuditedEmployees.Add(Employees.UnloadColumn("Employee"));
				MessageParameters.ObjectName = "Object.Employees";
			ElsIf ArrayOfOperationDetails.Find("ActivityKinds.Employee") <> Undefined Then
				AuditedEmployees.Add(ActivityKinds.UnloadColumn("Employee"));
				MessageParameters.ObjectName = "Object.ActivityKinds";
			EndIf;
			
			ParametersForGettingEmployees = New Structure;
			ParametersForGettingEmployees.Insert("Organization", Organization);
			ParametersForGettingEmployees.Insert("BeginOfPeriod", Date);
			ParametersForGettingEmployees.Insert("PeriodEnding", Date);
			
			OperationalAccountingOfManufacturingPayrollAndHumanResources.CheckWorkingEmployees(AuditedEmployees, ParametersForGettingEmployees, Cancel, MessageParameters);
		Else
		//--WE
		
		
		//++WE	
		EndIf;
		//--WE
		
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		MessageText = NStr("vi = 'Bộ phận tiền tệ của trích dẫn cho các loại công việc không được đặt. Tiền tệ được đặt trong phần ""NSI và Quản trị \ Sản xuất"".';
							|ru = 'Не задана валюта расценок на виды работ. Валюта задается в разделе ""НСИ и администрирование \ Производство"".';
							|en = 'Currency of activity kind rates is not specified. The currency is set in Master data and settings / Manufacturing.'; fa = 'ارز نرخ‌های نوع فعالیت مشخص نشده است. ارز در داده‌های پایه و تنظیمات / تولید تنظیم می‌شود.';
							|it = 'Non è indicata la valuta dei costi di lavori. La valuta deve essere indicata nella sezione ""Dati principali e impostazioni \ Produzione"".';
							|pl = 'Nie ustawiaj kursów walut dla pracy. Waluta jest ustawiona w sekcji „NSI i administrowanie \ Produkcja"".';
							|tr = 'İş türlerine ilişkin oranların para birimi belirlenmedi. Para birimi, ""Master veri ve yönetim \ Üretim"" bölümünde belirtilmektedir.'");
		CommonClientServer.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	NotCheckedAttributeArray.Add("Currency");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load  Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// We are trying to re-fill in the Currency details if it is not filled in.
	If Not ValueIsFilled(Currency) Then
		Currency = Constants.CurrencyOfActivityKindRates.Get();
	EndIf;
	
	DocumentAmount = ActivityKinds.Total("Sum");
	If WorkOrderKind = Enums.TeamWorkOrderKinds.Personal Then
		Persons = ActivityKinds.UnloadColumn("Employee_");
		Persons = CommonClientServer.CollapseArray(Persons);
		Assignees = PersonsTM.ShortListOfIndividuals(Persons, Date);
	Else
		Assignees = Team;
	EndIf;
	
	If WorkOrderKind = Enums.TeamWorkOrderKinds.TeamKind Or
		AutoAllocation Then
		For Each String In ActivityKinds Do
			String.Employee_ = Undefined;
		EndDo;
	Else
		Employees.Clear();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	UpdateRelatedData();
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	UpdateRelatedData();
	
EndProcedure

#EndRegion

#Region Private

Procedure FillDefaultAttributes()
	
	Organization = SettingsValueCached.GetDefaultOrganization();
	EmployeeResponsible = Users.CurrentUser();
	Currency = Constants.CurrencyOfActivityKindRates.Get();
	
	If GetFunctionalOption("ComplexAutomation") Then
		WorkOrderKind = Enums.TeamWorkOrderKinds.TeamWithoutOrder21;
	EndIf;
	
EndProcedure

#Region Other

Procedure UpdateRelatedData()
	
	Stages = New Array;
	
	For Each String In ActivityKinds Do
		
		If TypeOf(String.ReferenceOrder) = Type("DocumentRef.ProductionStage2_2")
			And Stages.Find(String.ReferenceOrder) = Undefined Then
			
			Stages.Add(String.ReferenceOrder);
			
		EndIf;
		
	EndDo;
		
	If Stages.Count() > 0 Then
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.ProductionStageStates = True;
		
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			Stages,
			"ACTION_REFRESH_STATE_WORK_DESIGN",
			RegistersToBeReflected);
			
	EndIf;
	
	Return; // empty handler
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

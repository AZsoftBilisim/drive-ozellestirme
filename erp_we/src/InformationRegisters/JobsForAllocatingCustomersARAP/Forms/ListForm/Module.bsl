
#Region FormCommandsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	BorderDate = CurrentSessionDate();
	FillInOrganizationSelectionList();
EndProcedure

&AtClient
Procedure ResetBorders(Command)
	DropBordersOnServer(BegOfMonth(BorderDate), CompanyBorder);
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInOrganizationSelectionList()
	ChoiceList = Items.CompanyBorder.ChoiceList;
	ChoiceList.LoadValues(Catalogs.Companies.AvailableCompanies(True));
	ChoiceList.Insert(0, Catalogs.Companies.EmptyRef(), NStr("vi = '<Theo tất cả doanh nghiệp>';
															|ru = '<По всем организациям>';
															|en = '<By all companies>'; fa = '<By all companies>';
															|it = '<per tutte le società>';
															|pl = '<dla wszystkich firm>';
															|tr = '<Tüm iş yerleri için>'"));
EndProcedure

&AtServer
Procedure DropBordersOnServer(BorderDate, Organization)
	
	If Not ValueIsFilled(Organization) Then
		OrganizationTasks = Catalogs.Companies.AvailableCompanies(True);
	Else
		OrganizationTasks = Organization;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		
		Item = Block.Add("InformationRegister.JobsForAllocatingCustomersARAP");
		Item.Mode = DataLockMode.Exclusive;
		If TypeOf(OrganizationTasks) = Type("CatalogRef.Companies") Then
			Item.SetValue("Organization", OrganizationTasks);
		Else // this is an array of organizations
			LockTable = New ValueTable;
			LockTable.Columns.Add("Organization");
			LockTable.LoadColumn(OrganizationTasks, "Organization");
			
			Item.DataSource = LockTable;
			Item.UseFromDataSource("Organization", "Organization");
		EndIf;
		
		Item = Block.Add("Constant.NumberOfJobForAllocatingCustomersARAP");
		Item.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		Query = New Query("
		|SELECT ALLOWED TOP 1
		|	1
		|FROM
		|	InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
		|WHERE
		|	Jobs.Organization IN (&Organization)
		|	AND Jobs.Month < &NewBorderDate
		|;
		|//////////////////////////////////////////////
		|SELECT DISTINCT ALLOWED
		|	CalculationsAreSummarized.AccountingDimensionByPartners,
		|	CalculationsAreSummarized.Organization,
		|	CalculationsAreSummarized.ARAPObject AS ARAPObject
		|FROM
		|	(SELECT DISTINCT 
		|		Calculations.AccountingDimensionByPartners,
		|		Calculations.AccountingDimensionByPartners.Organization AS Organization,
		|		Calculations.ARAPObject AS ARAPObject
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting AS Calculations
		|	WHERE
		|		Calculations.AccountingDimensionByPartners.Organization IN (&Organization)
		|		AND Calculations.Period >= &NewBorderDate
		|		AND Calculations.Sum <> 0
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		OfflineCalculations.AccountingDimensionByPartners,
		|		OfflineCalculations.AccountingDimensionByPartners.Organization AS Organization,
		|		OfflineCalculations.SalesOrder AS ARAPObject
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDocuments AS OfflineCalculations
		|	WHERE
		|		OfflineCalculations.AccountingDimensionByPartners.Organization IN (&Organization)
		|		AND OfflineCalculations.Period >= &NewBorderDate
		|	) AS CalculationsAreSummarized
		|");
		
		Query.SetParameter("Organization", OrganizationTasks);
		Query.SetParameter("NewBorderDate", BorderDate);
		QueriesArray = Query.ExecuteBatch();
		
		ThereAreBoundariesInPast = QueriesArray[0].IsEmpty();
		If Not ThereAreBoundariesInPast Then
			ExceptionText = NStr("vi = 'Khổng thể dịch chuyển giới hạn sau này, so với giới hạn cũ.';
								|ru = 'Нельзя сдвигать границы в будущее, относительно старых границ.';
								|en = 'Cannot move borders to the future in regard to old borders.'; fa = 'Cannot move borders to the future in regard to old borders.';
								|it = 'Non è consentito spostare i limiti nel futuro rispetto i limiti precedenti.';
								|pl = 'Nie można przenieść granic w przyszłość, stosunkowo do starych granic.';
								|tr = 'Eski sınırlara kıyasta sınırlar geleceğe doğru kaydırılamaz.'");
			Raise ExceptionText;
		Else
			JobNumber = Constants.NumberOfJobForAllocatingCustomersARAP.Get();
			NewFrontiers = QueriesArray[1].Select();
			While NewFrontiers.Next() Do
				Set = InformationRegisters.JobsForAllocatingCustomersARAP.CreateRecordSet();
				Set.Filter.AccountingDimensionByPartners.Set(NewFrontiers.AccountingDimensionByPartners);
				Set.Filter.Organization.Set(NewFrontiers.Organization);
				Set.Filter.ARAPObject.Set(NewFrontiers.ARAPObject);
				Set.Filter.Month.Set(BorderDate);
				Set.Filter.JobNumber.Set(JobNumber);
				
				RecordingTask = Set.Add();
				FillPropertyValues(RecordingTask, NewFrontiers); 
				RecordingTask.Month = BorderDate;
				RecordingTask.JobNumber = JobNumber;
				
				Set.Write(True);
			EndDo;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể chuyển giới hạn nhiệm vụ do: %Cause%';
							|ru = 'Не удалось перенести границы заданий по причине: %Cause%';
							|en = 'Cannot transfer job limits. Reason: %Cause%'; fa = 'Cannot transfer job limits. Reason: %Cause%';
							|it = 'Impossibile spostare i limiti dei task a causa di: %Cause%';
							|pl = 'Nie powiodło się przeniesienie granic zadań z powodu: %Cause%';
							|tr = 'Bu nedenle görev sınırları taşınamadı: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,
			Metadata.InformationRegisters.JobsForAllocatingCustomersARAP, MessageText);
			
		CommonClientServer.MessageToUser(MessageText);
	EndTry
EndProcedure

#EndRegion



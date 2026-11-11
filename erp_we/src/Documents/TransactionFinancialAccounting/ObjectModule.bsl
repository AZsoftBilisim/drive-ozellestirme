#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Organization = Common.CommonSettingsStorageLoad("CurrentCompany", "");
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If TypeOf(FillingData) = Type("DocumentRef.TransactionFinancialAccounting")
	 Or TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And FillingData.Property("ChartOfAccounts") Then
		
		If TypeOf(FillingData) = Type("Structure") Then
			DocumentBasis = FillingData.Basis;
			MetadataBases_ = Metadata.FindByType(TypeOf(DocumentBasis));
			ChartOfAccountsOfBasis = FillingData.ChartOfAccounts;
		Else
			DocumentBasis = FillingData;
			MetadataBases_ = DocumentBasis.Metadata();
			ChartOfAccountsOfBasis = Common.ObjectAttributeValue(DocumentBasis, "ChartOfAccounts");
		EndIf;
		
		If Metadata.Documents.Find(MetadataBases_.Name) <> Undefined Then
			FillPropertyValues(ThisObject, DocumentBasis,,"Date,Number");
			ChartOfAccounts = ChartOfAccountsOfBasis;
			Comment = "";
			
			NewRow = ThisObject.RecordsFilling.Add();
			NewRow.Document = DocumentBasis;
			
			PostingGenerationSetting = FinancialAccountingServerCached.UsedSettingsForGeneratingTransactions(
				BegOfMonth(CurrentSessionDate()), ChartOfAccounts, Organization);
			
			MethodOfCancelingTransactions = Common.ObjectAttributeValue(PostingGenerationSetting, "MethodOfCancelingTransactions");
			OptionForGeneratingTransactions = Common.ObjectAttributeValue(ChartOfAccountsOfBasis, "OptionForGeneratingTransactions");
			
			If MethodOfCancelingTransactions = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings Then
				TransactionContent = NStr("vi = 'Đảo ngược';
											|ru = 'Реверс';
											|en = 'Reverse'; fa = 'معکوس';
											|it = 'Inversa';
											|pl = 'Rewers';
											|tr = 'Ters'", Common.DefaultLanguageCode()) + " " + String(DocumentBasis);
			Else
				TransactionContent = NStr("vi = 'Đảo ngược';
											|ru = 'Сторно';
											|en = 'Storno'; fa = 'استورنو';
											|it = 'Storno';
											|pl = 'Storno';
											|tr = 'İptal'", Common.DefaultLanguageCode()) + " " + String(DocumentBasis);
			EndIf;
			
			If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
				PostingsStorno = AccountingRegisters.International.PostingsStorno(DocumentBasis,
					FillingData.ChartOfAccounts, CurrentSessionDate());
				
				Postings = RegisterRecords.International;
				For Each AccountingEntry In PostingsStorno Do
					NewEntry = Postings.Add();
					FillPropertyValues(NewEntry, AccountingEntry);
					NewEntry.Active = False;
					Postings.InstallExtdimension(NewEntry, AccountingEntry, "Dr");
					Postings.InstallExtdimension(NewEntry, AccountingEntry, "Cr");
				EndDo;
			Else
				PostingsStorno = AccountingRegisters.InternationalWithoutCorrespondence.PostingsStorno(DocumentBasis,
					FillingData.ChartOfAccounts, CurrentSessionDate());
				
				Postings = RegisterRecords.InternationalWithoutCorrespondence;
				For Each AccountingEntry In PostingsStorno Do
					NewEntry = Postings.Add();
					FillPropertyValues(NewEntry, AccountingEntry);
					NewEntry.Active = False;
					Postings.InstallExtdimension(NewEntry, AccountingEntry);
				EndDo;
			EndIf;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("Array") Then
		
		TypesOfFoundationDocument = Metadata.FindByType(TypeOf(Ref)).TabularSections.RecordsFilling.Attributes.Document.Type;
		
		For Each FillingDocument In FillingData Do
			
			If TypesOfFoundationDocument.ContainsType(TypeOf(FillingDocument)) Then
				
				FillPropertyValues(ThisObject, FillingDocument,,"Date,Number,Posted");
				BeginningOfContent = ?(TransactionContent = "", NStr("vi = 'ĐIỀU CHỈNH:';
																	|ru = 'КОРРЕКТИРОВКА:';
																	|en = 'ADJUSTMENT:'; fa = 'ADJUSTMENT:';
																	|it = 'CORREZIONE:';
																	|pl = 'KOREKTA:';
																	|tr = 'DÜZELTME'") + " ", TransactionContent + ", ");
				Comment = "";
				Content = BeginningOfContent + String(FillingDocument);
				NewRow = RecordsFilling.Add();
				NewRow.Document = FillingDocument;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If EnterPeriodByRows Then
		RegisterRecords.International.AdditionalProperties.Insert("EnterPeriodByRows", EnterPeriodByRows);
	EndIf;
	// Filling in the register details Period, Organization
	For Each RecordSet In RegisterRecords Do
		
		If RecordSet.Count() = 0 Then
			Continue;
		EndIf;
		
		EmptyTable   = RecordSet.UnloadColumns(); // ValueTable - 
		ThereIsChartOfAccounts  = EmptyTable.Columns.Find("ChartOfAccounts") <> Undefined;
		ThereIsACompany = EmptyTable.Columns.Find("Organization") <> Undefined;
		ThereIsPeriod      = EmptyTable.Columns.Find("Period") <> Undefined;
		
		If Not (ThereIsACompany Or ThereIsPeriod Or ThereIsChartOfAccounts) Then
			Continue;
		EndIf;
		
		RegisterRecordTable = RecordSet.Unload();
		If ThereIsChartOfAccounts Then
			RegisterRecordTable.FillValues(ChartOfAccounts, "ChartOfAccounts");
		EndIf;
		If ThereIsACompany Then
			RegisterRecordTable.FillValues(Organization, "Organization");
		EndIf;
		If ThereIsPeriod And Not EnterPeriodByRows Then
			RegisterRecordTable.FillValues(Date, "Period");
		EndIf;
		RecordSet.Load(RegisterRecordTable);
	
	EndDo;
	
	SetMotionActivity(WriteMode);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	
	Set = CopiedObject.RegisterRecords.International;
	Set.Read();
	CurObjectSet = RegisterRecords.International;
	If Set.Count() > 0 Then
		
		For Each SetRecord In Set Do
			
			NewRecord = CurObjectSet.Add();
			NewRecord.Period = Date;
			FillPropertyValues(NewRecord, SetRecord,,"Period,Recorder,ExtDimensionsDr,ExtDimensionsCr");
			NewRecord.Active = False;
			
			For Each ExtDimension In SetRecord.ExtDimensionsDr Do
				NewRecord.ExtDimensionsDr[ExtDimension.Key] = ExtDimension.Value;
			EndDo;
			
			For Each ExtDimension In SetRecord.ExtDimensionsCr Do
				NewRecord.ExtDimensionsCr[ExtDimension.Key] = ExtDimension.Value;
			EndDo;
			
		EndDo;// by set records
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetMotionActivity(WriteMode)
	
	Active = WriteMode = DocumentWriteMode.Posting Or WriteMode = DocumentWriteMode.Write And Posted;
	
	SetPrivilegedMode(True);
	
	For Each Movement In RegisterRecords Do
		
		If Movement.Write = False Then // When the form is working, the set may already be "touched" (read, modified)
			// Nobody touched the set
			Movement.Read();
		EndIf;
		
		For Each String In Movement Do
			
			If String.Active = Active Then
				Continue;
			EndIf;
			
			String.Active   = Active;
			Movement.Write = True; // In case the set was read above
			
		EndDo;
		
		If WriteMode = DocumentWriteMode.UndoPosting Then
			Movement.Write();
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
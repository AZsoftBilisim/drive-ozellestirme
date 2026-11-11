
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	CurCurrentDebtAssessmentAddress = Parameters.DebtAssessmentAddress;
	
	CurDebtAssessmentProcedure = GetFromTempStorage(CurCurrentDebtAssessmentAddress);
	If CurDebtAssessmentProcedure <> Undefined Then
		DebtEvaluationProcedure.Load(CurDebtAssessmentProcedure);
	EndIf;
	FillInTreeOfDebtAssessmentProcedure();
	
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.FinancialAccountingPolicy);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProcedureForAssessingDebtTree

&AtClient
Procedure ProcedureForAssessingDebtTreeBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	curData = Items.ProcedureForAssessingDebtTree.CurrentData;
	If curData = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	// We forbid copying the type of debt.
	
	If curData.ThisIsTypeOfDebt And Copy Then
		Cancel = True;
		Return;
	EndIf;
	
	DebtKind_Data = ?(curData.ThisIsTypeOfDebt, curData, curData.GetParent());
	DebtKind_CurrentRow = DebtKind_Data.GetID();
	
	Interval_Data = ?(curData.ThisIsTypeOfDebt, curData.GetItems()[0], curData);
	
	If Interval_Data.LowerBoundOfInterval = 0 Then
		
		// if no interval has been added, then change the Cur line.
		
		Cancel = True;
		
		Interval_Data.LowerBoundOfInterval = 1;
		
		Items.ProcedureForAssessingDebtTree.CurrentRow = Interval_Data.GetID();
		Items.ProcedureForAssessingDebtTree.CurrentItem = Items.ProcedureForAssessingDebtTreeEvaluation;
		Items.ProcedureForAssessingDebtTree.ChangeRow();
	ElsIf Not curData.ThisIsTypeOfDebt Then
		
		// Do not add lines that are subject to intervals. Instead, add a new interval.
		
		Cancel = True;
		
		Items.ProcedureForAssessingDebtTree.CurrentRow = DebtKind_Data.GetID();
		Items.ProcedureForAssessingDebtTree.AddRow();
	EndIf;
	
	FormBorderNames();
	
EndProcedure

&AtClient
Procedure ProcedureForAssessingDebtTreeOnChange(Item)
	
	FormBorderNames();
	
EndProcedure

&AtClient
Procedure ProcedureForAssessingDebtTreeOnStartEdit(Item, NewRow, Copy)
	
	DebtKind_CurrentRow = Items.ProcedureForAssessingDebtTree.CurrentData.GetParent().GetID();
	
EndProcedure

&AtClient
Procedure ProcedureForAssessingDebtTreeOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	FormBorderNames();
	
EndProcedure

&AtClient
Procedure ProcedureForAssessingDebtTreeBeforeDeleteRow(Item, Cancel)
	
	curData = Items.ProcedureForAssessingDebtTree.CurrentData;
	If curData = Undefined Or curData.ThisIsTypeOfDebt Then
		Cancel = True;
		Return;
	EndIf;
	
	CurParent = curData.GetParent();
	DebtKind_CurrentRow = CurParent.GetID();
	
	// If the last interval is deleted, then we clear it.
	
	If CurParent.GetItems().Count() = 1 Then
		Cancel = True;
		DebtKind_CurrentRow = -1;
		
		curData.DebtKind = "";
		curData.LowerBoundOfInterval = 0;
		curData.UpperBoundOfInterval = 0;
		curData.Evaluation = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcedureForAssessingDebtTreeEvaluationOnChange(Item)
	
	curData = Items.ProcedureForAssessingDebtTree.CurrentData;
	If curData.Evaluation > 100 Then
		curData.Evaluation = 100;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	FillInTableOfDebtAssessmentProcedure();
	SaveToStorageOnServer();
	Close(Modified);
	
EndProcedure

&AtClient
Procedure FillByDefault(Command)
	
	// fills the Cur view of the debt with the default settings (45/90).
	
	curData = Items.ProcedureForAssessingDebtTree.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	DebtKind = ?(curData.ThisIsTypeOfDebt, curData.DebtKind, curData.GetParent().DebtKind);
	
	FillInTableOfDebtAssessmentProcedure();
	FillInDefaultDebtAssessmentIntervals(DebtKind);
	FillInTreeOfDebtAssessmentProcedure();
	
	Nodes = ProcedureForAssessingDebtTree.GetItems();
	For Each Node In Nodes Do
		Items.ProcedureForAssessingDebtTree.Expand(Node.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveToStorageOnServer()
	PutToTempStorage(DebtEvaluationProcedure.Unload(), CurCurrentDebtAssessmentAddress)
EndProcedure

&AtClient
Procedure FormBorderNames()
	
	curData = ProcedureForAssessingDebtTree.FindByID(DebtKind_CurrentRow);
	If curData = Undefined Then
		Return;
	EndIf;
	
	Intervals = curData.GetItems();
	
	NumberOfIntervals_ = Intervals.Count();
	NameOfTimeInterval = NStr("vi = 'Nhiều hơn %LowerBoundOfInterval% ngày';
								|ru = 'Свыше %LowerBoundOfInterval% дней';
								|en = 'Over %LowerBoundOfInterval% days'; fa = 'Over %LowerBoundOfInterval% days';
								|it = 'Oltre i %LowerBoundOfInterval% giorni';
								|pl = 'Ponad %LowerBoundOfInterval% dni';
								|tr = 'Günlerden %LowerBoundOfInterval% fazla'");
	NameOfIntervalFromTo = NStr("vi = 'Từ %LowerBoundOfInterval% đến %UpperBoundOfInterval% %DaysOfDays%';
								|ru = 'От %LowerBoundOfInterval% до %UpperBoundOfInterval% %DaysOfDays%';
								|en = '%LowerBoundOfInterval% to %UpperBoundOfInterval% %DaysOfDays%'; fa = '%LowerBoundOfInterval% to %UpperBoundOfInterval% %DaysOfDays%';
								|it = 'Da %LowerBoundOfInterval% a %UpperBoundOfInterval% %DaysOfDays%';
								|pl = 'Od %LowerBoundOfInterval% do %UpperBoundOfInterval% %DaysOfDays%';
								|tr = '%LowerBoundOfInterval% itibaren%UpperBoundOfInterval%%DaysOfDays% kadar'");
	UpperBoundOfInterval = 9999999999;
	
	For CurIndex__ = 1 To NumberOfIntervals_ - 1 Do
		PreviousStage = Intervals[CurIndex__ - 1];
		ThisStage = Intervals[CurIndex__];
		If ThisStage.LowerBoundOfInterval = 0 Then
			ThisStage.LowerBoundOfInterval = PreviousStage.LowerBoundOfInterval + 1;
		EndIf;
		
		While (CurIndex__ - 1 >= 0) And ThisStage.LowerBoundOfInterval < Intervals[CurIndex__ - 1].LowerBoundOfInterval Do
			Intervals.Move(CurIndex__,-1);
			CurIndex__ = CurIndex__ - 1;
		EndDo;
	EndDo;
	
	If NumberOfIntervals_ = 1 Then
		Intervals[0].LowerBoundOfInterval = 1;
		Intervals[0].UpperBoundOfInterval = UpperBoundOfInterval;
		Intervals[0].DebtKind = StrReplace(NameOfTimeInterval, "%LowerBoundOfInterval%",
			Intervals[0].LowerBoundOfInterval);
	ElsIf NumberOfIntervals_ > 1 Then
		Intervals[0].LowerBoundOfInterval = 1;
		
		For CurIndex__ = 1 To NumberOfIntervals_ - 1 Do
			PreviousStage = Intervals[CurIndex__ - 1];
			ThisStage = Intervals[CurIndex__];
			
			If ThisStage.LowerBoundOfInterval = PreviousStage.LowerBoundOfInterval Then
				ThisStage.LowerBoundOfInterval = PreviousStage.LowerBoundOfInterval + 1;
			EndIf;
			
			If CurIndex__ < NumberOfIntervals_ Then
				PreviousStage.UpperBoundOfInterval = Intervals[CurIndex__].LowerBoundOfInterval - 1;
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromTo,
					"%LowerBoundOfInterval%", PreviousStage.LowerBoundOfInterval);
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromToPresentation,
					"%UpperBoundOfInterval%", PreviousStage.UpperBoundOfInterval);
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromToPresentation,
					"%DaysOfDays%", ?(PreviousStage.UpperBoundOfInterval = 1, NStr("vi = 'ngày';
																					|ru = 'дня';
																					|en = 'day'; fa = 'روز';
																					|it = 'дня';
																					|pl = 'dnia';
																					|tr = 'gün'"), NStr("vi = 'ngày';
																										|ru = 'дней';
																										|en = 'days'; fa = 'روز';
																										|it = 'дней';
																										|pl = 'dni';
																										|tr = 'günler'")));
				PreviousStage.DebtKind = NameOfIntervalFromToPresentation;
			EndIf;
			
			Intervals[NumberOfIntervals_ - 1].UpperBoundOfInterval = UpperBoundOfInterval;
			Intervals[NumberOfIntervals_ - 1].DebtKind = StrReplace(NameOfTimeInterval,
				"%LowerBoundOfInterval%", Intervals[NumberOfIntervals_ - 1].LowerBoundOfInterval);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTableOfDebtAssessmentProcedure()
	
	DebtEvaluationProcedure.Clear();
	
	ElementsTypeOfDebt = ProcedureForAssessingDebtTree.GetItems();
	For Each LineTypeOfDebt In ElementsTypeOfDebt Do
		IntervalElements = LineTypeOfDebt.GetItems();
		For Each LineInterval In IntervalElements Do
			If Not ValueIsFilled(LineInterval.DebtKind) Then
				Continue;
			EndIf;
			
			NewRow = DebtEvaluationProcedure.Add();
			NewRow.DebtKind = LineTypeOfDebt.DebtKind;
			NewRow.IntervalName = LineInterval.DebtKind;
			
			FillPropertyValues(NewRow, LineInterval,, "DebtKind");
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTreeOfDebtAssessmentProcedure()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CurDebtAssessmentProcedure.DebtKind,
	|	CurDebtAssessmentProcedure.IntervalName,
	|	CurDebtAssessmentProcedure.LowerBoundOfInterval,
	|	CurDebtAssessmentProcedure.UpperBoundOfInterval,
	|	CurDebtAssessmentProcedure.Evaluation
	|INTO TT_CurDebtAssessmentProcedure
	|FROM
	|	&CurDebtAssessmentProcedure AS CurDebtAssessmentProcedure
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	KindsOfDebt.Ref AS DebtKind,
	|	ISNULL(TT_CurDebtAssessmentProcedure.IntervalName, """") AS IntervalName,
	|	ISNULL(TT_CurDebtAssessmentProcedure.LowerBoundOfInterval, 0) AS LowerBoundOfInterval,
	|	ISNULL(TT_CurDebtAssessmentProcedure.UpperBoundOfInterval, 0) AS UpperBoundOfInterval,
	|	ISNULL(TT_CurDebtAssessmentProcedure.Evaluation, 0) AS Evaluation
	|FROM
	|	Enum.KindsOfDebt AS KindsOfDebt
	|		LEFT JOIN TT_CurDebtAssessmentProcedure AS TT_CurDebtAssessmentProcedure
	|		ON KindsOfDebt.Ref = TT_CurDebtAssessmentProcedure.DebtKind
	|WHERE
	|	NOT KindsOfDebt.Ref = VALUE(Enum.KindsOfDebt.Other)
	|	AND (&UseLoanAndDepositContracts OR NOT KindsOfDebt.Ref = VALUE(Enum.KindsOfDebt.IssuedBorrowings))
	|	AND (&UseMultipleCurrencies OR NOT KindsOfDebt.Ref = VALUE(Enum.KindsOfDebt.CounterpartyAccountsReceivablesInForeignCurrency))
	|ORDER BY
	|	DebtKind,
	|	LowerBoundOfInterval
	|AUTOORDER
	|TOTALS
	|BY
	|	DebtKind";
	
	Query.SetParameter("CurDebtAssessmentProcedure", DebtEvaluationProcedure.Unload());
	Query.SetParameter("UseLoanAndDepositContracts", GetFunctionalOption("UseLoanAndDepositContracts"));
	Query.SetParameter("UseMultipleCurrencies", GetFunctionalOption("UseMultipleCurrencies"));
	
	Tree = FormAttributeToValue("ProcedureForAssessingDebtTree");
	Tree.Rows.Clear();
	
	SampleTypeOfDebt = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleTypeOfDebt.Next() Do
		NewRow = Tree.Rows.Add();
		NewRow.DebtKind = SampleTypeOfDebt.DebtKind;
		NewRow.ThisIsTypeOfDebt = True;
		
		SamplingIntervals = SampleTypeOfDebt.Select();
		While SamplingIntervals.Next() Do
			NewLineIntervals = NewRow.Rows.Add();
			NewLineIntervals.DebtKind = SamplingIntervals.IntervalName;
			
			FillPropertyValues(NewLineIntervals, SamplingIntervals,, "DebtKind");
		EndDo;
	EndDo;
	
	ValueToFormAttribute(Tree, "ProcedureForAssessingDebtTree");
	
EndProcedure

&AtServer
Procedure FillInDefaultDebtAssessmentIntervals(DebtKind)
	
	FoundRows = DebtEvaluationProcedure.FindRows(New Structure("DebtKind", DebtKind));
	For Each FoundRow In FoundRows Do
		DebtEvaluationProcedure.Delete(FoundRow);
	EndDo;
	
	DefaultIntervals = AccrualAndWriteOffOfBadDebtAlowancesServer.GetDefaultDebtAssessmentIntervals();
	For Each Interval In DefaultIntervals Do
		NewRow = DebtEvaluationProcedure.Add();
		FillPropertyValues(NewRow, Interval);
		NewRow.DebtKind = DebtKind;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Empty interval.
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", Metadata.StyleItems.EmptyTableField.Value);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Không đánh giá>';
																		|ru = '<Не оценивается>';
																		|en = '<Not evaluated>'; fa = '<Not evaluated>';
																		|it = '<Не оценивается>';
																		|pl = '<Not evaluated>';
																		|tr = '<Değerlendirilmiyor>'"));
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcedureForAssessingDebtTree.DebtKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProcedureForAssessingDebtTreeDebtKind.Name);
	
	// The tree element is a type of debt.
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcedureForAssessingDebtTree.ThisIsTypeOfDebt");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProcedureForAssessingDebtTree.Name);
	
	// For an interval with a 0 rating, add a description to the "Not charged" cell.
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", Metadata.StyleItems.EmptyTableField.Value);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa tính>';
																		|ru = '<Не начисляется>';
																		|en = '<Not accrued>'; fa = '<Not accrued>';
																		|it = '<Не начисляется>';
																		|pl = '<Not accrued>';
																		|tr = '<Tahakkuk edilmiyor>'"));
	
	DataSelectionGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcedureForAssessingDebtTree.DebtKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcedureForAssessingDebtTree.ThisIsTypeOfDebt");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcedureForAssessingDebtTree.Evaluation");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = 0;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProcedureForAssessingDebtTreeEvaluation.Name);
	
EndProcedure

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// get information about the transaction
	Query = New Query(
		"SELECT
		|	SalesOpportunitiesToCustomer.Ref,
		|	SalesOpportunitiesToCustomer.StartDate,
		|	SalesOpportunitiesToCustomer.Status,
		|	SalesOpportunitiesToCustomer.PotentialSaleAmount
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity");
	Query.SetParameter("SalesOpportunity", Parameters.Key);
	Selection = Query.Execute().Select();

	// determine the composition of the stages and the availability of editing
	If Selection.Next() Then
		SalesOpportunity     = Selection.Ref;
		StartDate = Selection.StartDate;
		Potential  = Selection.PotentialSaleAmount;

		// get a plan and actual dates for completing tasks on the transaction
		Query = New Query(
			"SELECT
			|	TransactionPlan.SaleProcessStage,
			|	StatisticsOfCustomerOpportunities.StartDate,
			|	StatisticsOfCustomerOpportunities.EndDate
			|FROM
			|	(SELECT
			|		SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
			|		CustomerOpportunityKindsSalesOpportunityStages.LineNumber AS LineNumber,
			|		CustomerOpportunityKindsSalesOpportunityStages.SaleProcessStage AS SaleProcessStage
			|	FROM
			|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
			|			INNER JOIN Catalog.CustomerOpportunityKinds.SalesOpportunityStages AS CustomerOpportunityKindsSalesOpportunityStages
			|			ON SalesOpportunitiesToCustomer.SalesOpportunityKind = CustomerOpportunityKindsSalesOpportunityStages.Ref
			|	WHERE
			|		SalesOpportunitiesToCustomer.Ref = &SalesOpportunity) AS TransactionPlan
			|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
			|		ON TransactionPlan.SalesOpportunity = StatisticsOfCustomerOpportunities.SalesOpportunity
			|			AND TransactionPlan.SaleProcessStage = StatisticsOfCustomerOpportunities.ProcessStep
			|
			|ORDER BY
			|	TransactionPlan.LineNumber");
		Query.SetParameter("SalesOpportunity", SalesOpportunity);
		StepsTable = Query.Execute();

		// check the correctness of the transaction type settings
		If StepsTable.IsEmpty() Then
				CommonClientServer.MessageToUser(
				NStr("vi = 'Tùy chỉnh sai dạng vụ việc.';
					|ru = 'Вид сделки настроен некорректно.';
					|en = 'Sales opportunity kind is invalid.'; fa = 'Sales opportunity kind is invalid.';
					|it = 'Il tipo di transazione è configurato in modo errato.';
					|pl = 'Rodzaj umowy został ustawiony niepoprawnie.';
					|tr = 'Satış fırsatı türü yanlış ayarlandı.'"));
			Enabled = False;
			Return;
		EndIf;//check the correctness of the transaction type settings

		StepsTable = StepsTable.Unload();
		StepsTable.Columns.Insert(0, "StageCheckBox");
		StepsTable.FillValues(False, "StageCheckBox");
		CurrentStep = SalesOpportunitiesServer.GetCurStage(SalesOpportunity);

		NumberOfStages = StepsTable.Count() - 1;
		ListLine = StepsTable.Find(CurrentStep, "SaleProcessStage");
		If ListLine = Undefined Then
			IndexOfCurrentStage = 0;
			StepsTable[0]["StartDate"] = StartDate;
		Else
			IndexOfCurrentStage = StepsTable.IndexOf(ListLine);
		EndIf;

		ValueToFormAttribute(StepsTable, "List");

		If Selection.Status <> Enums.OpportunityStatuses.InProgress Then
			Items.StartDate.ReadOnly = True;

			Items.WriteAndClose.Enabled       = False;
			Items.GroupMovementByStages.Enabled = False;
			Items.GoToTheSelectedStage.Enabled = False;
			Items.CancelButton_2.DefaultButton   = True;

			Items.GroupTheMovementOnTheStagesOfContext.Enabled  = False;
			Items.GoToTheSelectedStageButton.Enabled       = False;
		Else
			SetControlAvailability();
		EndIf;
	EndIf;//determine the composition of the stages and the availability of editing

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)

	If Item.CurrentItem.Name = "SaleProcessStage" Then
		Cancel = True;
		ShowValue(Undefined, Item.CurrentData.SaleProcessStage);
		Return;
	EndIf;

	If Item.CurrentRow = 0 Then
		Cancel = True;
	Else
		CurrentStartDate = Item.CurrentData.StartDate;
	EndIf;

EndProcedure

&AtClient
Procedure ListBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)

	If Item.CurrentItem.Name = "SaleProcessStage" Then
		CancelEdit = True;
		Cancel = True;
		ShowValue(Undefined, Item.CurrentData.SaleProcessStage);
		Return;
	EndIf;

	NewStartDate = Item.CurrentData.StartDate;
	CurrentRow = Item.CurrentRow;
	If NewStartDate < StartDate Then
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Ngày bắt đầu nhiệm vụ không được sớm hơn ngày bắt đầu vụ việc.';
				|ru = 'Дата начала задачи не должна быть раньше начала сделки.';
				|en = 'Start date of the task cannot be earlier than start date of the sales opportunity.'; fa = 'Start date of the task cannot be earlier than start date of the sales opportunity.';
				|it = 'La data di inizio del task non deve essere antecedente all''inizio della transazione.';
				|pl = 'Data rozpoczęcia zadania nie może być wcześniejsza od daty rozpoczęcia umowy.';
				|tr = 'Görevin başlangıç tarihi, satış fırsatının başlangıcından önce olmamalıdır.'"));
		Cancel = True;
	ElsIf CurrentStartDate = '0001.01.01' Then //transition to a new stage
		NewStageIndex = CurrentRow;
		For CntOfStages = 0 To NewStageIndex - 1 Do
			Stage = List.Get(CntOfStages);
			If Stage.StartDate = '0001.01.01' Or Stage.StartDate > NewStartDate Then
				Stage.StartDate = NewStartDate;
			EndIf;
			If Stage.EndDate = '0001.01.01' Or Stage.EndDate > NewStartDate Then
				Stage.EndDate = NewStartDate;
			EndIf;
			If CntOfStages = IndexOfCurrentStage Then
				List.Get(CntOfStages).EndDate = NewStartDate;
			EndIf;
		EndDo;
		Modified = True;
	ElsIf NewStartDate < CurrentStartDate Then // earlier date
		For CntOfStages = 0 To CurrentRow - 1 Do
			Stage = List.Get(CntOfStages);
			If Stage.StartDate > NewStartDate Then
				Stage.StartDate = NewStartDate;
			EndIf;
			If Stage.EndDate > NewStartDate Then
				Stage.EndDate = NewStartDate;
			EndIf;
		EndDo;
		Modified = True;
	ElsIf NewStartDate > CurrentStartDate Then // later date
		List.Get(CurrentRow - 1).EndDate = NewStartDate;
		For CntOfStages = CurrentRow To NumberOfStages Do
			Stage = List.Get(CntOfStages);
			If Stage.StartDate <> '0001.01.01' And Stage.StartDate < NewStartDate Then
				Stage.StartDate = NewStartDate;
			EndIf;
			If Stage.EndDate <> '0001.01.01' And Stage.EndDate < NewStartDate Then
				Stage.EndDate = NewStartDate;
			EndIf;
		EndDo;
		Modified = True;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Modified And Not ClosingInProgress Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
		               NStr("vi = 'Tất cả thông tin chưa được lưu sẽ bị mất. Vẫn đóng?';
							|ru = 'Вся несохраненная информация будет потеряна. Все равно закрыть?';
							|en = 'All unsaved data will be lost. Close anyway?'; fa = 'All unsaved data will be lost. Close anyway?';
							|it = 'Tutte le informazioni non salvate verranno perse. Chiudere lo stesso?';
							|pl = 'Cała wprowadzona informacja zostanie utracona. Zamknąć mimo wszystko?';
							|tr = 'Kaydedilmemiş tüm bilgiler kaybolacaktır. Yine de kapatılsın mı?'"),
		               QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)

	If Modified Then
		RecordStatistics();
		Notify("Write_StatisticsOfCustomerOpportunities", New Structure("SalesOpportunity",SalesOpportunity));
		ClosingInProgress = True;
		Close();
	Else
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure NextStage(Command)

	ChangeAStage(True);

EndProcedure

&AtClient
Procedure PreviousStage(Command)

	ChangeAStage(False);

EndProcedure

&AtClient
Procedure GoToTheSelectedStage(Command)

	NewStageIndex = Items.List.CurrentRow;

	If NewStageIndex = IndexOfCurrentStage Then
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cần chọn giai đoạn khác với giai đoạn hiện tại';
				|ru = 'Необходимо выбрать этап отличный от текущего';
				|en = 'Select a step different from the current one'; fa = 'Select a step different from the current one';
				|it = 'È necessario selezionare una fase diversa da quella corrente';
				|pl = 'Należy wybrać etap różniący się od bieżącego';
				|tr = 'Mevcut olandan farklı bir aşama seçmeniz gerekmektedir'"));
	Else
		
		CurrentSessionDate = CommonClient.SessionDate();
		
		// transition to a later stage
		If NewStageIndex > IndexOfCurrentStage Then
			List.Get(IndexOfCurrentStage).EndDate = CurrentSessionDate;
			List.Get(NewStageIndex).StartDate      = CurrentSessionDate;
			For CntOfStages = IndexOfCurrentStage + 1 To NewStageIndex - 1 Do
				Stage = List.Get(CntOfStages);
				Stage.StartDate = CurrentSessionDate;
				Stage.EndDate = Stage.StartDate;
			EndDo;
		Else //transition to an earlier stage
			List.Get(IndexOfCurrentStage).StartDate  = '0001.01.01';
			List.Get(NewStageIndex).EndDate = '0001.01.01';
			For CntOfStages = NewStageIndex + 1 To IndexOfCurrentStage - 1 Do
				Stage = List.Get(CntOfStages);
				Stage.StartDate = '0001.01.01';
				Stage.EndDate = '0001.01.01';
			EndDo;
		EndIf;
		IndexOfCurrentStage = NewStageIndex;
		Modified = True;
		SetControlAvailability();
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
// Set the availability of transition commands depending on the current stage
Procedure SetControlAvailability()

	Items.PreviousStage.Enabled       = IndexOfCurrentStage > 0;
	Items.NextStage.Enabled        = IndexOfCurrentStage < List.Count() - 1;
	Items.ThePreviousStageButton.Enabled = Items.PreviousStage.Enabled;
	Items.NextStageButton.Enabled  = Items.NextStage.Enabled;

	For StageCounter = 0 To NumberOfStages Do
		List[StageCounter].StageCheckBox = (StageCounter = IndexOfCurrentStage);
	EndDo;

EndProcedure

&AtServer
// Write changes to the statistics register
Procedure RecordStatistics()
	
	SetPrivilegedMode(True);

	EmployeeResponsible = Users.CurrentUser();
	Statistics = InformationRegisters.StatisticsOfCustomerOpportunities.CreateRecordSet();
	Statistics.Filter.SalesOpportunity.Set(SalesOpportunity);
	For CntOfStages = 0 To IndexOfCurrentStage Do
		Stage = List.Get(CntOfStages);
		Record = Statistics.Add();
		Record.SalesOpportunity = SalesOpportunity;
		Record.ProcessStep = Stage.SaleProcessStage;
		Record.StartDate = Stage.StartDate;
		Record.EndDate = Stage.EndDate;
		Record.Potential = Potential;
		Record.EmployeeResponsible = EmployeeResponsible;
		If Stage.EndDate = Date(1,1, 1) Then
			Record.Result = Enums.OpportunityStatuses.InProgress;
			Record.Duration = 0;
		Else
			Record.Result = Enums.OpportunityStatuses.Won;
			Record.Duration = SalesOpportunitiesServer.Duration(Record.StartDate, Record.EndDate);
		EndIf;
	EndDo;
	Statistics.Write();

EndProcedure

&AtClient
// Transfer the current stage to the next or previous one
// Parameters:
// Forward is the direction of transition (true if forward).
//
Procedure ChangeAStage(GoForward)

	If GoForward Then
		
		CurrentSessionDate = CommonClient.SessionDate();
		
		List.Get(IndexOfCurrentStage).EndDate  = CurrentSessionDate;
		IndexOfCurrentStage = IndexOfCurrentStage + 1;
		List.Get(IndexOfCurrentStage).StartDate = CurrentSessionDate;
	Else
		List.Get(IndexOfCurrentStage).StartDate = '0001.01.01';
		IndexOfCurrentStage = IndexOfCurrentStage - 1;
		List.Get(IndexOfCurrentStage).EndDate = '0001.01.01';
	EndIf;

	SetControlAvailability();
	Modified = True;

EndProcedure

#EndRegion

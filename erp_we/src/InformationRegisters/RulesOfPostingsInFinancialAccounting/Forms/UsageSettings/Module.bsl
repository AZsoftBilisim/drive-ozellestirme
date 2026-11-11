
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("PostingTemplate") Then
	    MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẩu này';
							|ru = 'Непосредственное открытие этой формы не предусмотрено';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane';
							|tr = 'Bu formun doğrudan açılması sağlanamadı'");
	    Raise MessageText;
	EndIf;
	
	PostingTemplate = Parameters.PostingTemplate;
	
	FillInListOfTransactionGenerationSettings();
	
	SetAvailabilityOfItemsOnServer();
	
EndProcedure

&AtClient
Procedure OnClose()
	
	Notify("ChangedUseInRulesOfReflectionInInternationalAccounting", , PostingTemplate); 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	ChangeRulesForReflectionInInternationalAccounting(ListOfTransactionGenerationSettings, PostingTemplate);
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfTransactionGenerationSettings()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReflectionRules.PostingGenerationSetting AS PostingGenerationSetting,
	|	ReflectionRules.PostingTemplate AS PostingTemplate
	|INTO ReflectionRules
	|FROM
	|	InformationRegister.RulesOfPostingsInFinancialAccounting AS ReflectionRules
	|WHERE
	|	ReflectionRules.PostingTemplate = &PostingTemplate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Settings.Ref AS PostingGenerationSetting,
	|	CASE
	|		WHEN ReflectionRules.PostingTemplate IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Use
	|FROM
	|	Catalog.FinancialAccountingPostingGenerationSetting AS Settings
	|	LEFT JOIN 
	|		ReflectionRules AS ReflectionRules
	|	ON 
	|		(ReflectionRules.PostingGenerationSetting = Settings.Ref)
	|WHERE
	|	Settings.Owner = &ChartOfAccounts
	|
	|ORDER BY
	|	Settings.Description";
	
	Query.SetParameter("PostingTemplate", PostingTemplate);
	Query.SetParameter("ChartOfAccounts", Common.ObjectAttributeValue(PostingTemplate,"ChartOfAccounts"));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		ListOfTransactionGenerationSettings.Add(Selection.PostingGenerationSetting,, Selection.Use);
	EndDo;

EndProcedure

&AtServerNoContext
Procedure ChangeRulesForReflectionInInternationalAccounting(ListOfTransactionGenerationSettings, PostingTemplate)

	RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingTemplate.Set(PostingTemplate);
	For Each ListItem In ListOfTransactionGenerationSettings Do
		If ListItem.Check Then
			NewRecord = RecordSet.Add();
			NewRecord.PostingGenerationSetting = ListItem.Value;
			NewRecord.PostingTemplate = PostingTemplate;
		EndIf;	
	EndDo;	
	RecordSet.Write();

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsOnServer()

	ItemArray = New Array;
	ItemArray.Add("FormWriteAndClose");
	ItemArray.Add("ListOfTransactionGenerationSettings");
	
	ChangingMFPSettingsIsAvailable = FinancialAccountingOfGeneralPurpose.InternationalAccountingSettingsCanBeChanged();
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not ChangingMFPSettingsIsAvailable);

EndProcedure

#EndRegion

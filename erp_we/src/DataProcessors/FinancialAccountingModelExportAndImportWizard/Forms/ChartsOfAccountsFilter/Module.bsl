#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Data = GetFromTempStorage(Parameters.AddressInTempStorage);
	
	ChartsOfAccounts.Load(Data.TableOfAccountPlans);
	FillInAccountPlansOfInternationalAccountingSettings(Data.SelectedTransactionSettings);
	FillOutAccountPlansOfTypicalOperations(Data.SelectedStandartOperations);
	
	SetConditionalAppearance();
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChartsOfAccounts

&AtClient
Procedure TableChartsOfAccountsMarkOnChange(Item)
	
	CurrentRow = CurrentItem.CurrentData;
	If Not CurrentRow.Check Then
		
		Filter = New Structure;
		Filter.Insert("ChartOfAccounts", CurrentRow.ChartOfAccounts);
		TransactionSettingsLines = AccountPlansForInternationalAccountingSettings.FindRows(Filter);
		LinesOfTypicalOperations = StandardTransactionAccountPlans.FindRows(Filter);

		
		If TransactionSettingsLines.Count() Or LinesOfTypicalOperations.Count() Then
			
			RowsArray = New Array;
			
			RowsArray.Add(NStr("vi = 'Hệ thống tài khoản được sử dụng trong các bộ lọc phụ thuộc';
								|ru = 'План счетов используется в зависимых отборах';
								|en = 'Chart of accounts is used in dependent filters'; fa = 'Chart of accounts is used in dependent filters';
								|it = 'Piano dei conti utilizzato nei filtri indipendenti';
								|pl = 'Plan kont jest używany w filtrach zależnych';
								|tr = 'Hesap planı bağlı filtrelerde kullanılıyor'"));
			
			If TransactionSettingsLines.Count() Then
				RowsArray.Add(StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Sẽ vô hiệu hóa kết xuất trong các tùy chỉnh bút toán: %1';
											|ru = 'Будет выключена выгрузка у настроек проводок: %1';
											|en = 'Export will be disabled for entry settings: %1'; fa = 'Export will be disabled for entry settings: %1';
											|it = 'Sarà attivato l''upload presso le impostazioni delle transazioni: %1';
											|pl = 'Zostanie wyłączony eksport ustawień wpisów księgowych: %1';
											|tr = 'Giriş ayarları için yükleme devre dışı bırakılacak: %1'"),
										TransactionSettingsLines[0].OutputRow));
			EndIf;
			
			If LinesOfTypicalOperations.Count() Then
				RowsArray.Add(StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Sẽ vô hiệu hóa kết xuất trong các giao dịch mẫu: %1';
											|ru = 'Будет выключена выгрузка у типовых операций: %1';
											|en = 'Export will be disabled for standard transactions: %1'; fa = 'Export will be disabled for standard transactions: %1';
											|it = 'Sarà attivato l''upload presso le operazioni di tipo: %1';
											|pl = 'Zostanie wyłączony eksport operacji typowych: %1';
											|tr = 'Standart işlemler için yükleme devre dışı bırakılacak: %1'"),
										LinesOfTypicalOperations[0].OutputRow));
			EndIf;
			
			RowsArray.Add(NStr("vi = 'Tiếp tục?';
								|ru = 'Продолжить?';
								|en = 'Continue?'; fa = 'Continue?';
								|it = 'Continuare?';
								|pl = 'Continue?';
								|tr = 'Devam edilsin mi?'"));

			QueryText = StrConcat(RowsArray, Chars.LF);
			
			ShowQueryBox(
					New CallbackDescription("ChangeMark1", ThisObject, CurrentRow),
					QueryText,
					QuestionDialogMode.YesNo);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	Close(AddressInTemporaryStorageOfChartsOfAccounts());
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	MarkTableElements(True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkTableElements(False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = Items.TableChartsOfAccountsMark.Name;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableChartsOfAccountsMark.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ChartsOfAccounts.RelatedSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Enabled", False);

	//
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = Items.TableChartsOfAccountsChartOfAccounts.Name;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableChartsOfAccountsChartOfAccounts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ChartsOfAccounts.RelatedSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure FillInAccountPlansOfInternationalAccountingSettings(SelectedTransactionSettings)
	
	QueryText =
		"SELECT
		|	FinancialAccountingPostingGenerationSetting.Ref AS DependentObject,
		|	FinancialAccountingPostingGenerationSetting.Owner AS ChartOfAccounts
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting AS FinancialAccountingPostingGenerationSetting
		|WHERE
		|	FinancialAccountingPostingGenerationSetting.Ref IN(&ReferencesArrray)
		|TOTALS BY
		|	ChartOfAccounts";
	
	FillInTable(AccountPlansForInternationalAccountingSettings, QueryText, SelectedTransactionSettings);
	
EndProcedure

&AtServer
Procedure FillOutAccountPlansOfTypicalOperations(SelectedStandartOperations)
	
	QueryText =
		"SELECT
		|	StandardTransactionsOfFinancialAccounting.Ref AS DependentObject,
		|	StandardTransactionsOfFinancialAccounting.ChartOfAccounts AS ChartOfAccounts
		|FROM
		|	Catalog.StandardTransactionsOfFinancialAccounting AS StandardTransactionsOfFinancialAccounting
		|WHERE
		|	StandardTransactionsOfFinancialAccounting.Ref IN(&ReferencesArrray)
		|TOTALS BY
		|	ChartOfAccounts";
	
	FillInTable(StandardTransactionAccountPlans, QueryText, SelectedStandartOperations);
	
EndProcedure

// Fill in the table.
// 
// Parameters:
//  Table - ValueTable
//  QueryText - String
//  ReferencesArrray - Array
&AtServer 
Procedure FillInTable(Table, QueryText, ReferencesArrray)
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select(QueryResultIteration.ByGroups);
	While Selection.Next() Do
		
		String = "";
		
		SelectionDetailRecords = Selection.Select();
		While SelectionDetailRecords.Next() Do
			String = String + ?(IsBlankString(String), "", ", ") + String(SelectionDetailRecords.DependentObject);
		EndDo;
		
		NewRow = Table.Add();
		NewRow.ChartOfAccounts = Selection.ChartOfAccounts;
		NewRow.OutputRow = String;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkTableElements(Check) 
	
	For Each String In ChartsOfAccounts Do
		
		If Not String.RelatedSelection Then
			String.Check = Check;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function AddressInTemporaryStorageOfChartsOfAccounts()
	Return PutToTempStorage(ChartsOfAccounts.Unload(), UUID)
EndFunction

&AtServer
Procedure SetVisibilityAvailability()
	
	Filter = New Structure;
	Filter.Insert("RelatedSelection", True);
	FoundRows = ChartsOfAccounts.FindRows(Filter);
	NumberOfRowsFound = FoundRows.Count();

	If NumberOfRowsFound Then
		
		Items.TableOfAccountPlans.ToolTip = NStr("vi = 'Màu xám là các phần tử có bộ lọc phụ thuộc, không nên bỏ chọn chúng';
												|ru = 'Серым цветом выделены элементы с зависимым отбором, отменить их выбор нельзя';
												|en = 'Items with dependent filter are highlighted in gray, you cannot unselect them'; fa = 'Items with dependent filter are highlighted in gray, you cannot unselect them';
												|it = 'Gli elementi con filtro dipendente sono evidenziati di grigio, non è possibile annullare la loro selezione';
												|pl = 'Szarym kolorem są podświetlone elementy z filtrem zależnym, wybór tych elementów nie można anulować';
												|tr = 'Bağımlı seçime sahip öğeler gri renkle vurgulanır, onların filtresini kaldıramazsınız'");
		Items.TableOfAccountPlans.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		
	Else
		
		Items.TableOfAccountPlans.ToolTip = "";
		Items.TableOfAccountPlans.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeMark1(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.No Then
		AdditionalParameters.Check = True;
	Else
		AdditionalParameters.Check = False;
	EndIf;
EndProcedure

#EndRegion

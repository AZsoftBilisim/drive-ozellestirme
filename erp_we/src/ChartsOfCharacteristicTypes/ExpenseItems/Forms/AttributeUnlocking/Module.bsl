
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AllowEditingOfTheTypeOfActivityAndTheCostAllocationOption = True;
	AllowEditingOfTheExpenseAnalyst = True;
	AllowEditingOfComplianceAccountingSettings = True;
	
	If Parameters.ExpenseTypeCategory = Enums.ExpenseActivityTypes.OtherActivity
		And Parameters.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences Then
		ProhibitUnlockingExpenseActivityCategory = True;
		Items.DescriptionCostAllocationOption.Title = 
			NStr("vi = 'Không nên thay đổi tùy chọn phân bổ chi phí nếu có chứng từ được kết chuyển phản ánh các chi phí mà dạng này được chỉ định.';
				|ru = 'Вариант распределения расходов не рекомендуется изменять, если есть проведенные документы отражения расходов, в которых указана данная статья.';
				|en = 'It is not recommended that you change the expense allocation option if there are posted expense documents with this item specified.'; fa = 'It is not recommended that you change the expense allocation option if there are posted expense documents with this item specified.';
				|it = 'Non è consigliabile modificare la variante di allocazione dei costi, se ci sono dei documenti registrati di visualizzazione delle spese in cui è indicato questo articolo.';
				|pl = 'Nie zaleca się zmian wariantu przydziału kosztów, jeśli istnieją zaksięgowane dokumenty odzwierciedlenia kosztów, w których wskazano daną pozycję.';
				|tr = 'Bu kalemde yer alan giderleri yansıtan deftere kaydedilmiş belgeler varsa, gider dağıtım seçeneğini değiştirmeniz önerilmemektedir.'");
		Items.AllowEditingOfTheTypeOfActivityAndTheCostAllocationOption.Title = 
			NStr("vi = 'Cho phép chỉnh sửa loại chi phí và phương án phân bổ chi phí';
				|ru = 'Разрешить редактирование типа расходов и варианта распределения расходов';
				|en = 'Allow editing expense type and expense allocation option'; fa = 'Allow editing expense type and expense allocation option';
				|it = 'Permettere la modifica del tipo delle spese e della variante di allocazione delle spese';
				|pl = 'Zezwól na edycję typu kosztów i wariantu przydziału kosztów';
				|tr = 'Gider türünü ve gider dağıtım seçeneğini düzenlemeye izin ver'");
	EndIf;
	
	If Parameters.Predefined Then
		
		ComplianceOfArticlesWithDistributionOptions = ChartsOfCharacteristicTypes.ExpenseItems.ComplianceOfArticlesWithDistributionOptions();
		ComplianceOfItemsWithTypesOfExpenses = ChartsOfCharacteristicTypes.ExpenseItems.ComplianceOfItemsWithTypesOfExpenses();
		
		DistributionOptions = ComplianceOfArticlesWithDistributionOptions.Get(Parameters.ExpenseItem);
		ExpensesOccur = ComplianceOfItemsWithTypesOfExpenses.Get(Parameters.ExpenseItem);
		
		If DistributionOptions <> Undefined
			And DistributionOptions.FindByValue(Parameters.CostAllocationOptionTax) <> Undefined
			And DistributionOptions.FindByValue(Parameters.CostAllocationOptionManag) <> Undefined
			And DistributionOptions.FindByValue(Parameters.CostAllocationOptionLocal) <> Undefined Then
			ProhibitionOfUnblockingDistributionOption = True;
			Items.DescriptionCostAllocationOption.Title = 
				NStr("vi = 'Không nên thay đổi dạng hoạt động, nếu có các chứng từ phản ánh chi phí đã kết chuyển mà trong đó đã chỉ ra dạng LCTT này.';
					|ru = 'Вид деятельности не рекомендуется изменять, если есть проведенные документы отражения расходов, в которых указана данная статья.';
					|en = 'It is not recommended that you change the activity type if there are posted expense documents with this item specified.'; fa = 'It is not recommended that you change the activity type if there are posted expense documents with this item specified.';
					|it = 'Non si consiglia di modificare il tipo di attività se esistono documenti di spese registrati in cui è indicata la voce in questione.';
					|pl = 'Nie zaleca się zmiany rodzaju działalności, jeśli są zatwierdzone dokumenty odzwierciedlenia rozchodów, w których jest podana ta pozycja.';
					|tr = 'Bu kalemde yer alan giderleri yansıtan deftere kaydedilmiş belgeler varsa, faaliyet türünü değiştirmeniz önerilmemektedir.'");
			Items.AllowEditingOfTheTypeOfActivityAndTheCostAllocationOption.Title = 
				?(ExpensesOccur = Undefined, NStr("vi = 'Cho phép chỉnh sửa kiểu chi phí và dạng lĩnh vực';
													|ru = 'Разрешить редактирование типа расходов и вида деятельности';
													|en = 'Allow editing expense type and activity type'; fa = 'Allow editing expense type and activity type';
													|it = 'Consentire la modifica del tipo di spese e del tipo di attività';
													|pl = 'Zezwól na edycję typu rozchodów i rodzaju działalności';
													|tr = 'Gider türünü ve faaliyet türünü düzenlemeye izin ver'"),
					NStr("vi = 'Cho phép chỉnh sửa dạng hoạt động chi phí';
						|ru = 'Разрешить редактирование вида деятельности расходов';
						|en = 'Allow editing expense activity type'; fa = 'Allow editing expense activity type';
						|it = 'Consentire modifica del tipo di attività e delle spese';
						|pl = 'Zezwól na edycję rodzaju działalności rozchodów';
						|tr = 'Faaliyet türünün giderlerini düzenlemeye izin ver'"));
		EndIf;
		
		If ExpensesOccur <> Undefined Then
			ProhibitionOfUnblockingTypeOfExpenses = True;
			Items.AllowEditingOfTheTypeOfActivityAndTheCostAllocationOption.Title = 
				?(DistributionOptions <> Undefined, NStr("vi = 'Cho phép chỉnh sửa dạng hoạt động chi phí';
														|ru = 'Разрешить редактирование вида деятельности расходов';
														|en = 'Allow editing expense activity type'; fa = 'Allow editing expense activity type';
														|it = 'Consentire modifica del tipo di attività e delle spese';
														|pl = 'Zezwól na edycję rodzaju działalności rozchodów';
														|tr = 'Faaliyet türünün giderlerini düzenlemeye izin ver'"),
					NStr("vi = 'Cho phép chỉnh sửa dạng hoạt động và phương án phân bổ chi phí';
						|ru = 'Разрешить редактирование вида деятельности и варианта распределения расходов';
						|en = 'Allow editing activity type and expenses allocation option'; fa = 'Allow editing activity type and expenses allocation option';
						|it = 'Consentire modifica del tipo di attività e dell''opzione di ripartizione delle spese';
						|pl = 'Zezwól na edycję rodzaju działalności i wariantu podziału kosztów';
						|tr = 'Faaliyet türünü ve gider dağıtım seçeneğini düzenlemeye izin ver'"));
		EndIf;
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = AttributesToEdit();
	Close(Result);

EndProcedure

&AtServer
Function AttributesToEdit()
	
	Result = New Array;
	If AllowEditingOfTheTypeOfActivityAndTheCostAllocationOption Then
		If Not ProhibitionOfUnblockingTypeOfExpenses Then
			Result.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Attributes.ExpensesOccur.Name);
		EndIf;
		If Not ProhibitUnlockingExpenseActivityCategory Then
			Result.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Attributes.ExpenseTypeCategory.Name);
		EndIf;
		If Not ProhibitionOfUnblockingDistributionOption Then
			Result.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Attributes.CostAllocationOptionManag.Name);
			Result.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Attributes.CostAllocationOptionLocal.Name);
			Result.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Attributes.CostAllocationOptionTax.Name);
		EndIf;
		Result.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Attributes.SeparateVATAccountingOption.Name);
	EndIf;
	If AllowEditingOfTheExpenseAnalyst Then
		Result.Add("ValueType");
	EndIf;
	
	If AllowEditingOfComplianceAccountingSettings Then
		CalculationOfCostLocalization.AddBlockedDetailsOfObjectAccordingToAIT(Result, True);
		ExpenseItemsLocalization.AddBlockedItemDetails(Result, True);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

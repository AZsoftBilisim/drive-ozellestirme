#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		If Not DimensionHierarchyIsOverwritten Then
			TabularSection = DimensionsHierarchy.Unload();
			TabularSection.FillValues(True, "Used");
			NewHierarchy = Catalogs.BudgetingLimits.DimensionsHierarchy(
				Owner,
				BudgetFlowOrBalanceItem,
				TabularSection);
			DimensionsHierarchy.Load(NewHierarchy);
			DimensionHierarchyIsOverwritten = True;
		EndIf;
		DimensionPresentation = Catalogs.BudgetingLimits.DimensionPresentation(ThisObject);
		If LimitsByBudgetingDataServer.BudgetFlowItemIsUsedInLimitSettings(BudgetFlowOrBalanceItem, False)
			Or LimitedTransaction = Enums.LimitedTransactions.Expenses Then
			If IsNew() Then
				ClearCacheOfLimitSettings = True;
			Else
				ComparisonAttributes = "BudgetFlowOrBalanceItem,Periodicity,DimensionPresentation,DeletionMark,LimitedTransaction";
				InitialAttributes = Common.ObjectAttributesValues(Ref, ComparisonAttributes);
				CurDetails_ = New Structure(ComparisonAttributes);
				FillPropertyValues(CurDetails_, ThisObject, ComparisonAttributes);
				ClearCacheOfLimitSettings = Not TMCommonUseClientServer.StructuresAreEqual(InitialAttributes,
					CurDetails_, ComparisonAttributes);
				If Not ClearCacheOfLimitSettings Then
					HierarchyOfLinkAnalytics = Common.ObjectAttributeValue(Ref,
						"DimensionsHierarchy").Unload();
					HierarchyOfLinkAnalytics.Columns.Delete("Ref");
					ClearCacheOfLimitSettings = Not Common.DataMatch(HierarchyOfLinkAnalytics,
						DimensionsHierarchy.Unload());
				EndIf;
			EndIf;
			If ClearCacheOfLimitSettings Then
				SetOfCacheSettingsLimits = InformationRegisters.BudgetingLimitSettingsCache.CreateRecordSet();
				SetPrivilegedMode(True);
				SetOfCacheSettingsLimits.Write();
				SetPrivilegedMode(False);
			EndIf;
		EndIf;
		
		If LimitedTransaction = Enums.LimitedTransactions.Expenses Then
		
			ErrorText = NStr("vi = 'Trong dòng %1 chưa chỉ định biểu thức điền đối tượng phân tích.';
							|ru = 'В строке %1 не указано выражение заполнения аналитики.';
							|en = 'Line %1 does not contain a dimension population expression.'; fa = 'Line %1 does not contain a dimension population expression.';
							|it = 'Line %1 does not contain a dimension population expression.';
							|pl = 'Line %1 does not contain a dimension population expression.';
							|tr = '%1 satırda boyut doldurma ifadesi belirtilmedi.'");
			
			For Each LineOfATabularSection In DimensionsHierarchy Do
				If ValueIsFilled(LineOfATabularSection.DimensionKind)
					And Not LineOfATabularSection.FillInAnalyticsWithSpecifiedValue
					And LineOfATabularSection.Used
					And Not ValueIsFilled(LineOfATabularSection.DimensionPopulationExpression) Then
					Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						ErrorText, LineOfATabularSection.LineNumber), , , , Cancel);
				EndIf;
			EndDo;
		
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
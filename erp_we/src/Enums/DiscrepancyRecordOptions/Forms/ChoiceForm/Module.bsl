
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If ValueIsFilled(Parameters.VariantOfDiscrepancies) Then
		
		ArrayOfOptionsForReflectingDiscrepancies = New Array();
		
		If Parameters.VariantOfDiscrepancies = Enums.DiscrepancyOptions.Surpluses Then
			
			ArrayOfOptionsForReflectingDiscrepancies.Add(Enums.DiscrepancyRecordOptions.RecogniseGoodsSurplusAsVendorsIncome);
			ArrayOfOptionsForReflectingDiscrepancies.Add(Enums.DiscrepancyRecordOptions.RecogniseGoodsSurplusAsOurIncome);
			Title = NStr("vi = 'Hãy chỉ ra phương án phản ánh hàng thừa';
						|ru = 'Укажите вариант отражения излишков';
						|en = 'Specify surpluses posting option'; fa = 'Specify surpluses posting option';
						|it = 'Indicate la modalità di rilevazione delle eccedenze';
						|pl = 'Określ opcję odzwierciedlenia nadwyżek';
						|tr = 'Fazlalık yansıtmak için seçeneği belirt'");
			
		ElsIf Parameters.VariantOfDiscrepancies = Enums.DiscrepancyOptions.Shortages Then
			
			ArrayOfOptionsForReflectingDiscrepancies.Add(Enums.DiscrepancyRecordOptions.GoodsShortageRecognisedAsVendorExpenses);
			ArrayOfOptionsForReflectingDiscrepancies.Add(Enums.DiscrepancyRecordOptions.GoodsShortageRecognisedAsThirdPartyExpenses);
			ArrayOfOptionsForReflectingDiscrepancies.Add(Enums.DiscrepancyRecordOptions.GoodsShortageRecognisedAsOtherExpenses);
			Title = NStr("vi = 'Hãy chỉ ra phương án phản ánh hàng thiếu';
						|ru = 'Укажите вариант отражения недостач';
						|en = 'Specify shortage posting option'; fa = 'Specify shortage posting option';
						|it = 'Indicate la modalità di rilevazione degli ammanchi';
						|pl = 'Określ opcję odzwierciedlenia niedoborów';
						|tr = 'Eksikliği yansıtmak için seçeneği belirt'");
			
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", ArrayOfOptionsForReflectingDiscrepancies, DataCompositionComparisonType.InList,, True);
		
	EndIf;
	
EndProcedure // Joining the Server()

#EndRegion

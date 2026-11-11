
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AutoTitle = False;
	Title = NStr("vi = 'Bán hàng chung';
				|ru = 'Совместные продажи';
				|en = 'Joint sales'; fa = 'فروش مشترک';
				|it = 'Vendite congiunte';
				|pl = 'Wspólne sprzedaże';
				|tr = 'Ortak satışlar'");
	
	FilterProducts = Parameters.Key;
		
	CommonClientServer.SetDynamicListFilterItem(
		ProductsSoldWithACurrentOne, 
		"ProductsPrerequisite", 
		FilterProducts, 
		DataCompositionComparisonType.Equal, 
		"ProductsPrerequisite", 
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ProductsWithWhichACurrentOneIsSold, 
		"ProductsResult", 
		FilterProducts, 
		DataCompositionComparisonType.Equal, 
		"ProductsResult", 
		True);
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion



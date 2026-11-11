
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Filter")
	 And Parameters.Filter.Property("Products")
	 And ValueIsFilled(Parameters.Filter.Products) Then
		
		List.SettingsComposer.Settings.Filter.Items.Clear();
		CommonClientServer.AddCompositionItem(
			List.SettingsComposer.Settings.Filter,
			"Products",
			DataCompositionComparisonType.Equal,
			Parameters.Filter.Products,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
		Parameters.Filter.Delete("Products");	
	EndIf;
	If GetFunctionalOption("UseProductSegments") Then
		Items.Products.Title = "Products / Segment ofproductitem";
	EndIf;
	If GetFunctionalOption("UsePartnersSegments") Then
		Items.Partner.Title = "Client / Segment clients";
	EndIf;
EndProcedure

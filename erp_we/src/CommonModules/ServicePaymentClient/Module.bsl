#Region Public

// Opens the service payment form.
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
Procedure OpenServicePaymentForm() Export
EndProcedure

// Opens the service's pricing plan selection form.
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  ServiceProviderCode	 - Number - code of the service organization 
//  Source -ClientApplicationForm - source of the form opening
//  ClosingNotification1 - CallbackDescription - notification of the closing of the fare selection form.
//
Procedure OpenFareSelectionForm(ServiceProviderCode, Source = Undefined, ClosingNotification1 = Undefined) Export
EndProcedure
 
#EndRegion

#Region Internal

// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
// 
// Parameters:
// 	Parameters - See CommonClientOverridable.OnStart.Parameters
//
Procedure OnStart(Parameters) Export
EndProcedure

#EndRegion 

<?php

namespace App\Modules\Auth\Requests;

use Illuminate\Foundation\Http\FormRequest;

class VerifyOtpRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'phone'   => ['required', 'string', 'regex:/^[6-9]\d{9}$/'],
            'otp'     => ['required', 'string', 'size:6'],
            'purpose' => ['sometimes', 'in:login,register,reset'],
            'role'    => ['sometimes', 'in:patient,physiotherapist'],
        ];
    }
}

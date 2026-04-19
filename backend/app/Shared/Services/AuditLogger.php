<?php

namespace App\Shared\Services;

use App\Modules\Auth\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Request;

class AuditLogger
{
    public function log(
        ?User  $user,
        string $action,
        string $resource,
        ?int   $resourceId = null,
        array  $oldValues  = [],
        array  $newValues  = [],
    ): void {
        // Never throw — audit must not break business logic
        try {
            DB::table('audit_logs')->insert([
                'user_id'     => $user?->id,
                'user_role'   => $user?->role,
                'action'      => $action,
                'resource'    => $resource,
                'resource_id' => $resourceId,
                'ip_address'  => Request::ip(),
                'user_agent'  => Request::userAgent(),
                'old_values'  => $oldValues ? json_encode($oldValues) : null,
                'new_values'  => $newValues ? json_encode($newValues) : null,
                'created_at'  => now(),
            ]);
        } catch (\Throwable) {
            // Silent — audit failures must never interrupt requests
        }
    }
}

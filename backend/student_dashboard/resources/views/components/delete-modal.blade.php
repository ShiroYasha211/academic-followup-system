<div
    x-show="showDeleteModal"
    class="modal-overlay"
    style="display: none;"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">
    <div
        class="modal-container"
        @click.away="showDeleteModal = false">
        <div class="modal-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
            </svg>
        </div>

        <h3 class="modal-title" x-text="modalTitle || 'تأكيد الحذف'"></h3>
        <p class="modal-message" x-text="modalMessage || 'هل أنت متأكد من رغبتك في حذف هذا العنصر؟ لا يمكن التراجع عن هذا الإجراء.'"></p>

        <div class="modal-actions">
            <button
                type="button"
                class="btn btn-secondary"
                @click="showDeleteModal = false">
                إلغاء الأمر
            </button>

            <form :action="deleteUrl" method="POST">
                @csrf
                @method('DELETE')
                <button type="submit" class="btn btn-danger">
                    تأكيد الحذف
                </button>
            </form>
        </div>
    </div>
</div>